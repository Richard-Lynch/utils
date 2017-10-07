#!/bin/bash

#---defaults---
all=1
run=1
clean=1
outputname="main"

# local vars
asmExtension=".asm"
cExtension=".c"
cppExtension=".cpp"
asmIndex=0
cIndex=0

# --- options ---
while getopts ":a:r:c:o:h" opt; do
    case $opt in 
        :)
            echo "option -$OPTARG requires arg" >&2 
            exit 1 ;; 
        h)
            echo "usage: casm [acroh]" >&2
            echo "a; 1=use all local files 0=dont']" >&2
            echo "c; 1=clear files[default] 0=don't" >&2
            echo "r; 1=run binary[default] 0=don't" >&2
            echo "o; set output name [main=default]" >&2
            echo "h; display help" >&2
            echo "example;" >&2
            echo "casm -a 0 main.c min.asm [must be passed targets]" >&2
            echo "casm -c 0 [doesn't clear files]" >&2
            echo "casm -r 0 [doesn't run binary]" >&2
            echo "casm -o test [binary is called test]" >&2
            exit 1 ;; 
        a) # build all = 1, specify tagets = 0
            all=$OPTARG ;; 
        r) # run after compile = 1
            run=$OPTARG 
            echo "running program at end" >&2 ;; 
        c) # cleanup output files = 1
            clean=$OPTARG
            echo "not cleaning files" >&2 ;;
        o) # set outputname
            outputname="$OPTARG"
            echo "using $outputname as binary name" >&2 ;;
        ?)
            echo "unknown arg, quiting" >&2 
            exit 1 ;; 
    esac
done

shift $(($OPTIND -1)) # move the index so the next arg is $1

if [[ $all == 1 ]]  ; then
    args="$(ls)"
else
    args="$@"
fi

# --- loop over arguments --- 
for arg in $args ; do
# parse name and extension
    target=$(basename $arg)
    name="${target%.*}"
    extension=".${target##*.}"

# decide filetype
    if [[ "$extension" == "$asmExtension" ]] ; then
        # if asm, assemble and add to list
        touch $name.o $name.lst $name
        rm $name.o $name.lst $name 
        nasm -f elf -l "$name.lst" "$name$extension"  # asemble .asm into .o using nasm, and elf (32 bit) 
        asmLst[$asmIndex]="$name.lst"
        asmO[$asmIndex]="$name.o"
        asmIndex=$((asmIndex+1))
    elif [[ "$extension" == "$cExtension" ]] || [[ "$extension" == "$cppExtension" ]] ; then
        # if c or cpp, use as main
        if [[ $outputname == "" ]] ; then
            outputname=$name
        fi
        mainExtension=$extension
        cFiles[cIndex]=$name$extension
        cIndex=$((cIndex+1))
    elif [[ "$extension" == ."$name" ]] ; then
       echo "" > /dev/null 
    else
        echo "$name$extension : invalid extension, ignoring"> /dev/null
    fi
done
# --- compile --- 
if [[ "$mainExtension" == "$cExtension" ]] ; then
    # note : to include asm; extern $returnType $funcName($func params);
    gcc -m32 -o "$outputname" ${cFiles[*]} ${asmO[*]} # link using gcc (m32=32 bit, requires multicompile, external commands can be added here)
elif [[ "$mainExtension" == "$cppExtension" ]] ; then
    # note : to include asm; extern $returnType $funcName($func params) asm("$funcName");
    g++ -m32 -o "$outputname" ${cFiles[*]} ${asmO[*]} # link using gcc (m32=32 bit, requires multicompile, external commands can be added here)
else
    echo "unknown file extension for main"
fi
# --- cleanup --- 
if [[ $clean == 1 ]] ; then
    rm ${asmLst[*]} ${asmO[*]}
fi
# --- run --- 
if [[ $run == 1 ]] ; then
    ./$outputname
fi


