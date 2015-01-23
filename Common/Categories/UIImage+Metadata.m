#import "UIImage+Metadata.h"

#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>

@implementation UIImage (Metadata)

- (void)updateMetadata:(NSMutableDictionary *)imageProperties
 withCompletionHandler:(void(^)(NSData *imageData))completionHandler
{
    void(^updateBlock)(UIImage*, NSDictionary*) = ^(UIImage *image, NSDictionary *metadata) {
        // This is just so we don't have the '(__bridge NSString*)' copy-pasta everywhere
        NSString* MITCGImageDestinationLossyCompressionQuality = (__bridge NSString*)kCGImageDestinationLossyCompressionQuality;
        NSString* MITCGImagePropertyOrientation = (__bridge NSString*)kCGImagePropertyOrientation;
        NSString* MITCGImagePropertyGPSDictionary = (__bridge NSString*)kCGImagePropertyGPSDictionary;
        NSString* MITCGImagePropertyGPSLatitude = (__bridge NSString*)kCGImagePropertyGPSLatitude;
        NSString* MITCGImagePropertyGPSLatitudeRef = (__bridge NSString*)kCGImagePropertyGPSLatitudeRef;
        NSString* MITCGImagePropertyGPSLongitude = (__bridge NSString*)kCGImagePropertyGPSLongitude;
        NSString* MITCGImagePropertyGPSLongitudeRef = (__bridge NSString*)kCGImagePropertyGPSLongitudeRef;
        
        
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        
        NSString *imageUTI = (__bridge_transfer NSString*)CGImageSourceGetType(imageSource);
        DDLogVerbose(@"found %lu images in source of type %@",CGImageSourceGetCount(imageSource),imageUTI);
        
        NSMutableData *outputImageData = [[NSMutableData alloc] init];
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)outputImageData,
                                                                                  (__bridge CFStringRef)imageUTI,
                                                                                  1,
                                                                                  NULL);
        
        NSDictionary *existingMetadata = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource,0,NULL);
        NSMutableDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
        [imageMetadata addEntriesFromDictionary:existingMetadata];
        
        imageMetadata[MITCGImageDestinationLossyCompressionQuality] = @(0.75);
        
        if (!imageMetadata[MITCGImagePropertyOrientation]) {
            imageMetadata[MITCGImagePropertyOrientation] = @([image imageOrientation]);
        }
        
        if (!imageMetadata[MITCGImagePropertyGPSDictionary]) {
            NSMutableDictionary *gpsMetadata = [[NSMutableDictionary alloc] init];
            CLLocationManager *locationManager = [[CLLocationManager alloc] init];
            CLLocation *location = [locationManager location];
            
            if (location) {
                gpsMetadata[MITCGImagePropertyGPSLatitude] = @(fabs(location.coordinate.latitude));
                gpsMetadata[MITCGImagePropertyGPSLatitudeRef] = ((location.coordinate.latitude >= 0) ? @"N" : @"S");
                gpsMetadata[MITCGImagePropertyGPSLongitude] = @(fabs(location.coordinate.longitude));
                gpsMetadata[MITCGImagePropertyGPSLongitudeRef] = ((location.coordinate.longitude >= 0) ? @"E" : @"W");
                imageMetadata[MITCGImagePropertyGPSDictionary] = gpsMetadata;
            }
        }
        
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, (__bridge CFDictionaryRef)imageMetadata);
        CGImageDestinationFinalize(imageDestination);
        CFRelease(imageDestination);
        CFRelease(imageSource);
        
        imageData = outputImageData;
        
        if( completionHandler ) completionHandler( imageData );
    };
    
    updateBlock( self, imageProperties );
}

@end
