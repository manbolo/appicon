#!/usr/bin/env stsh
#-<void>processIconForApp:appId
framework:AppKit load.
framework:EGOS_Cocoa load.

nonChars := NSCharacterSet letterCharacterSet invertedSet.
str := '_'.
[ :self  |
    ((self componentsSeparatedByCharactersInSet:nonChars) componentsJoinedByString:str) lowercaseString
] installInClass: NSString  withMethodHeaderString:'slugString'.

mask := http://raw.githubusercontent.com/manbolo/appicon/master/maskInverted.png.
appInfo := ref:http://itunes.apple.com/us/lookup  getWithArgs id: appId

iconURL := var:appInfo/results/0/artworkUrl512.
name := var:appInfo/results/0/trackCensoredName.
icon := context evaluateScriptString: iconURL.

#(1024 512 120 114 60 57 ) do:[ :width  |
    c := MPWCGBitmapContext rgbBitmapContext: width @ width.
    c scale: width / icon pixelsWide.
    c maskedBy:mask draw:[ :aContext | aContext drawImage:icon. ].
    scaled := c image.
    outname := name slugString ,'_', width stringValue, '_', width stringValue , '_.png'.
    file:{outname} := scaled representationUsingType:4 properties:nil.
].
