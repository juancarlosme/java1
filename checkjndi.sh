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

if [[ $OSTYPE == 'darwin'* ]]; then
    jars=`find $tld -fstype local -type f \( -iname "*.jar" -o -iname "*.war" -o -iname "*.ear" \)`
else
    jars=`find $tld -mount -type f \( -iname "*.jar" -o -iname "*.war" -o -iname "*.ear" \)`
fi

for jar in $jars
    do
        patched=""
        hasjndi=`unzip -l $jar 2> /dev/null | grep -E "JndiLookup.class$"`
        hasmpc=`unzip -l $jar 2> /dev/null | grep -E "MessagePatternConverter.class$"`
        hasjars=`unzip -l $jar 2> /dev/null | grep -Ei  ".jar$|.war$|.ear$" | grep -v "Archive: " | awk '{print $NF}'`
        if [ ! -z "$hasmpc" ]; then
            outfile="$(mktemp)"
            unzip -p $jar $hasmpc 2> /dev/null > $outfile
            ispatched=`grep 'Message Lookups are no longer supported' $outfile`
            if [ ! -z "$ispatched" ]; then
                patched=1  
            fi
            rm $outfile
        fi
        if [ ! -z "$hasjndi" ]; then
            if [ ! -z "$patched" ]; then
                echo "$jar contains JndiLookup.class  ** BUT APPEARS TO BE 2.16 OR NEWER **"
            else
                echo "WARNING: $jar contains JndiLookup.class"
            fi
        fi
               
        if [ ! -z "$hasjars" ]; then
            for subjar in $hasjars
                do
                    outfile="$(mktemp)"
                    unzip -p $jar $subjar 2> /dev/null > $outfile
                    hasjndi=`unzip -l $outfile 2> /dev/null | grep -E "JndiLookup.class$"`
                    hasmpc=`unzip -l $outfile 2> /dev/null | grep -E "MessagePatternConverter.class$"`   
                    if [ ! -z "$hasmpc" ]; then
                        unzip -p $subjar $hasmpc 2> /dev/null > $outfile
                        ispatched=`grep 'Message Lookups are no longer supported' $outfile`
                        if [ ! -z "$ispatched" ]; then
                            patched=1
                        fi
                    fi
                    if [ ! -z "$hasjndi" ]; then
                        if [ ! -z "$patched" ]; then
                            echo "$jar contains $subjar contains JndiLookup.class  ** BUT APPEARS TO BE 2.16 OR NEWER **"
                        else
                            echo "WARNING: $jar contains $subjar contains JndiLookup.class"
                        fi
                    fi
                    rm $outfile
                done
                
        fi
    done