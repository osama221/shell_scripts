#!/bin/bash
##this script compares the two folders together

if diff "/home/folder1/" "/home/folder2/" &> /dev/null ; then
    echo "Files in the two folders are the same"    
else
    echo "Files in the two folders are NOT the same"
fi
