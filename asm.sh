#!/bin/bash

# yno file for yes no checks
source /home/norm/programs/scripts/yno.sh

expextedExtension=".asm"

target=$(basename $1)
name="${target%.*}"
extension=".${target##*.}"
echo $target $name $extension

if [[ "$extension" == "$expextedExtension" ]] ; then
    echo "ext ==  asm"
elif [[ "$extension" == ."$name" ]] ; then
    echo "no ext"
    echo "Input does not have .asm extension, assume .asm file exists?"
    yno
    case $yno_response in
        1)
            name="$1"
            extension="$expextedExtension"
            ;;
        *)
            echo "exiting"
            exit 1
            ;;
    esac
else
    echo "ext != asm"
    echo "invalid filetype on input file"
    exit 1
fi

# if [[ $extension == "$expextedExtension" ]] ; then
    touch $name.o $name.lst $name
    rm $name.o $name.lst $name # the * will silence errors if files dont exist
    nasm -f elf -l "$name.lst" "$name$extension" # asemble the scripts using nasm, and elf (32 bit)
    gcc -m32 -o "$name" "$name.o" # link using gcc (m32=32 bit, requires multicompile, external commands can be added here)
# else
#     echo "Input file not *$expextedExtension"
#     exit 1
# fi


