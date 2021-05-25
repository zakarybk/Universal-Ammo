#!/bin/bash
if [ $# -eq 0 ]
	then
	echo "No reason for addon update supplied"
	exit 1
fi

echo "Creating GMA: "
sh ./create-gma.sh

echo "Uploading to the Workshop"
str="$*"
"P:\Games\Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -addon "./temp.gma" -id "893205646" -changes "$str"