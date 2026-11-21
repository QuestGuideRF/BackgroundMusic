#!/bin/bash
# vim: tw=0:

# This file is part of Background Music.
#
# Background Music is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 2 of the
# License, or (at your option) any later version.
#
# Background Music is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Background Music. If not, see <http://www.gnu.org/licenses/>.

#
# quick_install.sh
# BGMDriver
#
# Copyright © 2016 Kyle Neideck
#
# Installs the HAL plugin to /Library/Audio/Plug-Ins/HAL and restarts coreaudiod to enable it.
# For testing/debugging.
#
# If BGMDevice is set as your default device when you run this, you might have to change your
# default device and change it back to BGMDevice to get programs that use audio working again.
# Or you can just restart those programs.
#

# Safe mode
set -euo pipefail
IFS=$'\n\t'

# The dir containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_FILENAME="$( basename "$0" )"
# Use the same filename as this script but change the extension to .conf
CONFIG_FILENAME="${SCRIPT_FILENAME%%.*}.conf"
# This config file just stores the paths to your BGMDriver builds (at least so far)
CONFIG_FILE="${SCRIPT_DIR}/${CONFIG_FILENAME}"

# Sanity check
if [[ ! -f "${SCRIPT_DIR}/${SCRIPT_FILENAME}" ]]; then
    echo "Проверка не пройдена. Не удалось найти этот скрипт ($0) в SCRIPT_DIR (${SCRIPT_DIR})." >&2
    exit 1
fi

bold_face() {
    echo $(tput bold)$*$(tput sgr0)
}

usage() {
    echo "Использование: $0 [параметры]" >&2
    echo -e "\t-u\tТолько удалить" >&2
    echo -e "\t-d\tНе перезапускать coreaudiod" >&2
    echo -e "\t-r\tУстановить release-сборку (по умолчанию debug)" >&2
    echo -e "\t-h\tПоказать эту справку" >&2
    exit 1
}

# Read in the config variables. (One var per line, formatted like "VARIABLE_NAME=value")
read_quick_install_conf() {
    # Set config vars to the empty string if they aren't set in the config file
    DRIVER_PATH_RELEASE=
    DRIVER_PATH_DEBUG=

    if [[ -f "${CONFIG_FILE}" ]]; then
        while IFS='' read -r LINE || [[ -n "${LINE}" ]]; do
            # Take the chars before the first "=" to get the var name
            # ("%%" deletes the longest substring match, starting at the end of the string)
            if [[ "DRIVER_PATH_DEBUG" = "${LINE%%=*}" ]]; then
                # Remove the "VARIABLE_NAME=" part to get the value
                DRIVER_PATH_DEBUG="${LINE/DRIVER_PATH_DEBUG=}"
            fi

            if [[ "DRIVER_PATH_RELEASE" = "${LINE%%=*}" ]]; then
                DRIVER_PATH_RELEASE="${LINE/DRIVER_PATH_RELEASE=}"
            fi
        done < "${CONFIG_FILE}"
    else
        touch "${CONFIG_FILE}"
    fi
}

# Get the path to the build we're installing, from the user or their config, and set DRIVER_PATH to it
get_build_path() {
    if [[ ${USE_RELEASE_BUILD} == true ]] && [[ "${DRIVER_PATH_RELEASE}" != "" ]] && [[ -d "${DRIVER_PATH_RELEASE}" ]]; then
        # The path to the release build was set, so just set it as the build we're installing
        DRIVER_PATH="${DRIVER_PATH_RELEASE}"
    elif [[ ${USE_RELEASE_BUILD} == false ]] && [[ "${DRIVER_PATH_DEBUG}" != "" ]] && [[ -d "${DRIVER_PATH_DEBUG}" ]]; then
        # The path to the debug build was set, so just set it as the build we're installing
        DRIVER_PATH="${DRIVER_PATH_DEBUG}"
    else
        # The build path isn't set yet, so ask the user to enter it
        echo -n "Введите абсолютный путь к вашей "
        ([[ ${USE_RELEASE_BUILD} == true ]] && echo -n "релизной ") || echo -n "отладочной ")
        echo "сборке BGMDriver. Пример:"
        echo -n "/Users/$(whoami)/Library/Developer/Xcode/DerivedData/BGM-somerandomchars/Build/Products/"
        ([[ ${USE_RELEASE_BUILD} == true ]] && echo -n "Release") || echo -n "Debug"
        echo "/Background Music Device.driver"
        cd /
        read -e -p ": /" DRIVER_PATH
        cd -

        # Add leading "/", strip trailing "/"
        DRIVER_PATH="/${DRIVER_PATH%/}"

        # Offer to abort if they entered an invalid path
        if [[ ! -d "${DRIVER_PATH}/Contents/MacOS" ]]; then
            if [[ ! -d "${DRIVER_PATH}" ]]; then
                echo "$(bold_face Предупреждение): этот путь, похоже, не является каталогом. Все равно продолжить?" >&2
            else
                echo "$(bold_face Предупреждение): этот каталог, похоже, не является bundle. Все равно продолжить?" >&2
            fi

            read -p "[y/N]: " CONTINUE_ANYWAY

            if [[ "${CONTINUE_ANYWAY}" != "y" ]]; then
                exit 1
            fi
        fi

        # Write the path to the config file
        if [[ ${USE_RELEASE_BUILD} == true ]]; then
            echo "DRIVER_PATH_RELEASE=${DRIVER_PATH}" >> "${CONFIG_FILE}"
        else
            echo "DRIVER_PATH_DEBUG=${DRIVER_PATH}" >> "${CONFIG_FILE}"
        fi
    fi
}

UNINSTALL_ONLY=false
DONT_RESTART_COREAUDIOD=false
USE_RELEASE_BUILD=false

# Parse options

while getopts ":udrh" opt; do
    case $opt in
        u)
            UNINSTALL_ONLY=true
            ;;
        d)
            DONT_RESTART_COREAUDIOD=true
            ;;
        r)
            USE_RELEASE_BUILD=true
            ;;
        h)
            usage
            ;;
        \?)
            echo "Недопустимый параметр: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Require sudo

sudo -v

# Get the path to the build we're installing

if [[ ${UNINSTALL_ONLY} == false ]]; then
    read_quick_install_conf
    get_build_path
fi

# Remove installed build

HAL_PLUGINS_DIR="/Library/Audio/Plug-Ins/HAL"
INSTALLED_DRIVER_PATH="${HAL_PLUGINS_DIR}/Background Music Device.driver"

if [[ -d "${INSTALLED_DRIVER_PATH}" ]]; then
    echo "$(bold_face Удаление старой версии драйвера)"

    # Sanity check
    INSTALLED_DRIVER_SIZE_KB="$(du -sk "${INSTALLED_DRIVER_PATH}" | cut -f1)"
    if [[ ! "${INSTALLED_DRIVER_SIZE_KB}" =~ ^-?[0-9]+$ ]] || [[ "${INSTALLED_DRIVER_SIZE_KB}" -gt 2048 ]]; then
        echo "$(bold_face Прерывание). Установленный драйвер в \"${INSTALLED_DRIVER_PATH}\" оказался намного больше ожидаемого (>2MB)." >&2
        exit 1
    fi

    # ("set -x" so the command is echoed)
    (set -x; sudo rm -rf "${INSTALLED_DRIVER_PATH}")
fi

# Install new build

if [[ ${UNINSTALL_ONLY} == false ]]; then
    echo -n "$(bold_face Установка драйвера) - "
    ([[ ${USE_RELEASE_BUILD} == true ]] && echo -n "релизная ") || echo -n "отладочная ")
    echo "сборка. (Измените или удалите ${CONFIG_FILENAME}, чтобы поменять путь к сборке.)"

    # ("set -x" so the command is echoed)
    (set -x; sudo cp -r "${DRIVER_PATH}" "${HAL_PLUGINS_DIR}")
fi

# Restart coreaudiod to load the installed build

if [[ ${DONT_RESTART_COREAUDIOD} == false ]]; then
    echo "$(bold_face Перезапуск coreaudiod). Если запущенное приложение перестанет воспроизводить звук, смените устройство вывода по умолчанию (и верните обратно при необходимости) или откройте BGMApp."

    # ("set -x" so the command is echoed)
    (set -x; sudo launchctl kill SIGTERM system/com.apple.audio.coreaudiod || sudo killall coreaudiod)
fi


