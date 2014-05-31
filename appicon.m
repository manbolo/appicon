#!/usr/bin/env objc-run
@import Foundation;
@import AppKit;

// To make an executable of this file:
// comment the first line and run
// clang -g -fmodules -framework Foundation -framework AppKit -o appicon appicon.m

#pragma mark - NSImage+Mask Category

// MDAdditions / NSImage+Mask.m
// Borrowed from https://github.com/mdamjanic7/MDAdditions/blob/master/NSImage%2BMask.m
//

@implementation NSImage (Mask)

+ (NSImage *)maskImage:(NSImage *)image usingMaskImage:(NSImage *)maskImage
{
    // Make sure the arguments are provided; if not, simply return the original image.
    // If the original image isn't provided, nil will be returned.
    if (!image || !maskImage){
        return image;
    }
    
    // Create a CGImage holding the mask image
    CGImageSourceRef maskSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)[maskImage TIFFRepresentation], NULL);
    CGImageRef maskRef = CGImageSourceCreateImageAtIndex(maskSourceRef, 0, NULL);
    
    // Create a mask from the provided mask image
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    // Create a CGImage that represents the source image
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
    
    // Perform the actual masking
    CGImageRef maskedImage = CGImageCreateWithMask(imageRef, mask);
    
    // Convert the output into NSImage
    NSImage *result = [[NSImage alloc] initWithCGImage:maskedImage size:image.size];
    
    // Release the memory used for creating the mask
    CFRelease(maskSourceRef);
    CGImageRelease(maskRef);
    CGImageRelease(mask);
    
    // Release the memory used for masking the image
    CFRelease(imageSourceRef);
    CGImageRelease(imageRef);
    CGImageRelease(maskedImage);
    
    return result;
}

- (NSImage *)maskUsingMaskImage:(NSImage *)maskImage
{
    return [NSImage maskImage:self usingMaskImage:maskImage];
}

@end


#pragma mark - NSImage+Thumbnail Category

// url2thumb / url2thumb / NSImage+Thumbnail.m
// Borrowed from https://github.com/timestretch/url2thumb/blob/master/url2thumb/NSImage%2BThumbnail.m
//

@implementation NSImage (Thumbnail)

- (NSBitmapImageRep *)bitmap
{
    [self lockFocus];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, self.size.width, self.size.height)];
    [self unlockFocus];
    return bitmap;
}

- (NSImage *)resizeToWidth:(NSInteger)outputWidth
{
    NSInteger outputHeight = round((self.size.height/(float)self.size.width) * outputWidth);
    NSImage *resultImage = [[NSImage alloc] initWithSize:NSMakeSize(outputWidth, outputHeight)];
    [resultImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [[self bitmap] drawInRect:NSMakeRect(0.0, 0.0, outputWidth, outputHeight)];
    [resultImage unlockFocus];
    return resultImage;
}

- (NSData*)pngData
{
    return [[self bitmap] representationUsingType:NSPNGFileType properties:nil];
}

@end


#pragma mark - NSString+Slug Category


@implementation NSString (Slug)

- (NSString *)slugString
{
    NSCharacterSet *filterSet = [[NSCharacterSet letterCharacterSet]
                                 invertedSet];
    NSString *slug = [[self componentsSeparatedByCharactersInSet:filterSet] componentsJoinedByString:@"-"];
    return [slug lowercaseString];
}

@end


/*
 *
 */
void downloadIcon(NSString *iconURLString, NSString *title, NSImage *mask)
{
    NSURL *iconURL = [NSURL URLWithString:iconURLString];
    NSImage *icon = [[NSImage alloc] initWithContentsOfURL:iconURL];
    NSImage *iconMasked = [icon maskUsingMaskImage:mask];
    
    for(NSNumber *size in @[@1024, @512, @120, @114, @60, @57]){
        NSInteger width = [size integerValue];
        NSImage *iconResized = [iconMasked resizeToWidth:width];
        
        NSData *data = [iconResized pngData];
        [data writeToFile:[NSString stringWithFormat:@"icon_%@_%ld_%ld.png", title, width, width] atomically:YES];
    }
    
}

/*
 *
 */
void downloadAppMetadata(NSString *appId, NSImage *mask)
{
    NSLog(@"download_app_json %@\n", appId);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/us/lookup?id=%@", appId]];
    NSData *resultsData = [NSData dataWithContentsOfURL:url];
    if (!resultsData) {
        NSLog(@"Error downloading %@", url);
        return;
    }
    
    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:resultsData options:0 error:nil];
    
    NSDictionary *meta = results[@"results"][0];
    NSString *iconURL = meta[@"artworkUrl512"];
    NSString *title = [meta[@"trackCensoredName"] slugString];
    
    downloadIcon(iconURL, title, mask);
    
}


/*
 * Download the mask from Github, this way we don't
 * have to provide mask.png and the script is self contained.
 */
NSImage* downloadIconMask()
{
    NSURL *maskURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/manbolo/appicon/master/maskInverted.png"];
    NSImage *mask = [[NSImage alloc] initWithContentsOfURL:maskURL];
    return mask;
}


void downloadApps()
{
    NSArray *appIds = @[
                        @"400274934",  // Meon
                        @"598581396",  // Kingdom Rush Frontiers
                        ];
    
    NSImage *mask = downloadIconMask();
    
    for(NSString *appId in appIds){
        downloadAppMetadata(appId, mask);
    }
}


int main()
{
    downloadApps();
}




