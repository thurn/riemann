#!/bin/bash

# modified version of process_assets script by user DDRBoxman on Github.
# https://github.com/DDRBoxman/Android-SVG-Asset-Generator/
# Requires Inkscape to be installed.
# This script scales and creates images at the correct dpi level for Android.
# When creating svg files set the image size to the size that you want your mdpi images to be.


function processImage {
  file=$(basename $1)
  case $OSTYPE in
  darwin*)
    inkscape="/Applications/Inkscape.app/Contents/Resources/bin/inkscape"
    ;;
  *)
    inkscape="inkscape"
    ;;
  esac

  $inkscape -d 480 -e ./res/drawable-xxhdpi/${file/.svg}.png $1 >& /dev/null
  $inkscape -d 320 -e ./res/drawable-xhdpi/${file/.svg}.png $1 >& /dev/null
  $inkscape -d 240 -e ./res/drawable-hdpi/${file/.svg}.png $1 >& /dev/null
  $inkscape -d 160 -e ./res/drawable-mdpi/${file/.svg}.png $1 >& /dev/null
}

for f in $(find ./assets -name *.svg -type f) ;
do
  echo "Processing $f"
  processImage $f
done
