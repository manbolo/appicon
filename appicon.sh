#!/bin/bash
set -eu 
    
curl -s "https://raw.githubusercontent.com/manbolo/appicon/master/mask.png" >"icon_mask.png"
    
for app_id in "$@"
do
    metadata=$(curl -s "http://itunes.apple.com/us/lookup?id=$app_id")
    icon_url=$(echo $metadata | jq -r ".results[0].artworkUrl512")
    name=$(echo $metadata | jq -r ".results[0].trackCensoredName")
    
    icon_base="icon_$name"
    curl -s "$icon_url" >"$icon_base.png"
    convert "$icon_base.png" "icon_mask.png" -compose copy-opacity -composite "$icon_base.png"
        
    for size in 1024 512 120 114 60 57
    do
    convert "$icon_base.png" -resize "${size}x${size}" "${icon_base}_${size}x${size}.png"
    done
done
    
rm icon_mask.png
