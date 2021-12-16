#!/bin/bash

tld=$1

if [ -z "$tld" ]; then
    tld='.'
fi

unzip=`which unzip`
if [ -z "$unzip" ]; then
    echo "This script requires unzip to function properly"
    exit 1
fi

process_jar() {
    patched=""
    hasjndi=""
    printed=""
    if [ -z "$2" ]; then
        parent=$1
    else
        parent=$2
    fi

    if [ -z "$3" ]; then
        subjarfilename=""
    else
        subjarfilename="$3"
    fi


    jndifile=`unzip -l $1 2> /dev/null | grep -E "JndiLookup.class$"`
    mpcfile=`unzip -l $1 2> /dev/null | grep -E "MessagePatternConverter.class$"`
    jarfiles=`unzip -l $1 2> /dev/null | grep -Ei  ".jar$|.war$|.ear$" | grep -v "Archive: " | awk '{print $NF}'`
    if [ ! -z "$mpcfile" ]; then
        outfile="$(mktemp)"
        unzip -p $1 $mpcfile 2> /dev/null > $outfile
        ispatched=`grep 'Message Lookups are no longer supported' $outfile`
        if [ ! -z "$ispatched" ]; then
            patched=1
        fi
        #rm $outfile
    fi

    if [ ! -z "$jndifile" ]; then
        hasjndi=1
        if [ ! -z "$subjarfilename" ]; then
            outputstring="$parent contains $subjarfilename contains JndiLookup.class"
        else
            outputstring="$parent contains JndiLookup.class"
        fi
    fi

    if [ ! -z "$jarfiles" ]; then
        for subjar in $jarfiles
            do
                subjarfile="$(mktemp)"
                unzip -p $1 $subjar 2> /dev/null > $subjarfile
                #echo "Extracting $subjar from $1 to $subjarfile"
                process_jar "$subjarfile" "$parent" "$subjar"
                rm $subjarfile 2> /dev/null
            done

    fi

    if [ ! -z "$mpcfile" ]; then
        rm $outfile 2> /dev/null
    fi

    if [ ! -z "$patched" ]; then
        outputstring="$outputstring ** BUT APPEARS TO BE 2.16 OR NEWER **"
    fi

    if [ -z "$printed" ]; then
        if [ ! -z "$hasjndi" ]; then
            if [ ! -z "$patched" ]; then
                echo "$outputstring"
            else
                echo "WARNING: $outputstring"
            fi
            printed=1
        fi
    fi
}

if [[ $OSTYPE == 'darwin'* ]]; then
    jars=`find $tld -fstype local -type f \( -iname "*.jar" -o -iname "*.war" -o -iname "*.ear" \)`
else
    jars=`find $tld -mount -type f \( -iname "*.jar" -o -iname "*.war" -o -iname "*.ear" \)`
fi

OLDIFS=$IFS
IFS=$'\n'
for jar in $jars
    do
        process_jar "$jar"
    done
IFS=$OLDIFS
