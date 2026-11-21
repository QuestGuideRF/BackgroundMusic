#!/bin/sh

#
# Iconizer shell script by Steve Richey (srichey@floatlearning.com)
#
# This is a simple tool to generate all necessary app icon sizes and the JSON file for an *EXISTING* Xcode project from one file.
# To use: specify the path to your vector graphic (PDF format) and the path to your Xcode folder containing Images.xcassets
# Example: sh iconizer.sh MyVectorGraphic.pdf MyXcodeProject
#
# Requires ImageMagick: http://www.imagemagick.org/

if [ $# -ne 2 ]
  then
        echo "\nИспользование: sh iconizer.sh file.pdf FolderName\n"
elif [ ! -e "$1" ]
    then
        echo "Файл $1 не найден; ожидался путь к векторному изображению.\n"
elif [ ${1: -4} != ".pdf" ]
    then
        echo "Файл $1 не является векторным изображением. Ожидался PDF-файл.\n"
elif [ ! -d "./$2/Images.xcassets/AppIcon.appiconset/" ]
    then
        echo "Папка Xcode $2 не найдена; ожидалась папка с Images.xcassets/AppIcon.appiconset/ \n"
else
    echo "Создание иконок из $1 в $2/Images.xcassets/AppIcon.appiconset/..."

    for i in 16 29 32 40 50 57 58 64 72 76 80 87 100 114 120 128 144 152 180 256 512 1024
        do
            echo "Создание иконки ${i}px"
            convert -density 400 $1 -scale $ix$i ./$2/Images.xcassets/AppIcon.appiconset/appicon_$i.png
    done

    echo "Файлы иконок созданы, запись Contents.json..."

    echo '{"images":[\n{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_29.png",\n"scale":"1x"\n},\n{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_58.png",\n"scale":"2x"\n},\n{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_87.png",\n"scale":"3x"\n},\n{\n"size":"40x40",\n"idiom":"iphone",\n"filename":"appicon_80.png",\n"scale":"2x"\n},\n{\n"size":"40x40",\n"idiom":"iphone",\n"filename":"appicon_120.png",\n"scale":"3x"\n},\n{\n"size":"57x57",\n"idiom":"iphone",\n"filename":"appicon_57.png",\n"scale":"1x"\n},\n{\n"size":"57x57",\n"idiom":"iphone",\n"filename":"appicon_114.png",\n"scale":"2x"\n},\n{\n"size":"60x60",\n"idiom":"iphone",\n"filename":"appicon_120.png",\n"scale":"2x"\n},\n{\n"size":"60x60",\n"idiom":"iphone",\n"filename":"appicon_180.png",\n"scale":"3x"\n},\n{\n"size":"29x29",\n"idiom":"ipad",\n"filename":"appicon_29.png",\n"scale":"1x"\n},\n{\n"size":"29x29",\n"idiom":"ipad",\n"filename":"appicon_58.png",\n"scale":"2x"\n},\n{\n"size":"40x40",\n"idiom":"ipad",\n"filename":"appicon_40.png",\n"scale":"1x"\n},\n{\n"size":"40x40",\n"idiom":"ipad",\n"filename":"appicon_80.png",\n"scale":"2x"\n},\n{\n"size":"50x50",\n"idiom":"ipad",\n"filename":"appicon_50.png",\n"scale":"1x"\n},\n{\n"size":"50x50",\n"idiom":"ipad",\n"filename":"appicon_100.png",\n"scale":"2x"\n},\n{\n"size":"72x72",\n"idiom":"ipad",\n"filename":"appicon_72.png",\n"scale":"1x"\n},\n{\n"size":"72x72",\n"idiom":"ipad",\n"filename":"appicon_144.png",\n"scale":"2x"\n},\n{\n"size":"76x76",\n"idiom":"ipad",\n"filename":"appicon_76.png",\n"scale":"1x"\n},\n{\n"size":"76x76",\n"idiom":"ipad",\n"filename":"appicon_152.png",\n"scale":"2x"\n},\n{\n"size":"120x120",\n"idiom":"car",\n"filename":"appicon_120.png",\n"scale":"1x"\n},\n{\n"size":"16x16",\n"idiom":"mac",\n"filename":"appicon_16.png",\n"scale":"1x"\n},\n{\n"size":"16x16",\n"idiom":"mac",\n"filename":"appicon_32.png",\n"scale":"2x"\n},\n{\n"size":"32x32",\n"idiom":"mac",\n"filename":"appicon_32.png",\n"scale":"1x"\n},\n{\n"size":"32x32",\n"idiom":"mac",\n"filename":"appicon_64.png",\n"scale":"2x"\n},\n{\n"size":"128x128",\n"idiom":"mac",\n"filename":"appicon_128.png",\n"scale":"1x"\n},\n{\n"size":"128x128",\n"idiom":"mac",\n"filename":"appicon_256.png",\n"scale":"2x"\n},\n{\n"size":"256x256",\n"idiom":"mac",\n"filename":"appicon_256.png",\n"scale":"1x"\n},\n{\n"size":"256x256",\n"idiom":"mac",\n"filename":"appicon_512.png",\n"scale":"2x"\n},\n{\n"size":"512x512",\n"idiom":"mac",\n"filename":"appicon_512.png",\n"scale":"1x"\n},\n{\n"size":"512x512",\n"idiom":"mac",\n"filename":"appicon_1024.png",\n"scale":"2x"\n}\n],\n"info":{\n"version":1,\n"author":"xcode"\n}\n}' > "./$2/Images.xcassets/AppIcon.appiconset/Contents.json"

    echo "Готово!"
fi
