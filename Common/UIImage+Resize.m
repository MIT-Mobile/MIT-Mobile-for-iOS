// UIImage+Resize.m
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

#import "UIImage+Resize.h"

@implementation UIImage (Resize)
-(UIImage*)imageByRotatingImageInRadians:(float)radians
{
	const size_t width = self.size.width;
	const size_t height = self.size.height;
    
    static CGColorSpaceRef rgbColorSpace = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ rgbColorSpace = CGColorSpaceCreateDeviceRGB(); });
	
    CGRect imgRect = CGRectMake(0.0, 0.0, width, height);
    
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, CGAffineTransformMakeRotation(radians));
    
    
	CGContextRef bmpContext = CGBitmapContextCreate(NULL,
                                                   rotatedRect.size.width,
                                                   rotatedRect.size.height,
                                                   8,
                                                   0,
                                                   rgbColorSpace,
                                                   kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	if (bmpContext == NULL)
    {
		return nil;
    }
    
	CGContextSetShouldAntialias(bmpContext, true);
	CGContextSetAllowsAntialiasing(bmpContext, true);
	CGContextSetInterpolationQuality(bmpContext, kCGInterpolationHigh);
    
	// Rotation here (based around the center)
	CGContextTranslateCTM(bmpContext,
                          (rotatedRect.size.width * 0.5),
                          (rotatedRect.size.height * 0.5));
	CGContextRotateCTM(bmpContext, radians);
    
	// Copy the image into the bitmap context
    CGRect drawRect = CGRectMake(-(width * 0.5),
                                 -(height * 0.5),
                                 width,
                                 height);
	CGContextDrawImage(bmpContext, drawRect, self.CGImage);
    
	// Create a UIImage object from the context
	CGImageRef rotatedImageRef = CGBitmapContextCreateImage(bmpContext);
	UIImage* rotated = [UIImage imageWithCGImage:rotatedImageRef];
    
	// Clean up the CF* stuff
	CGImageRelease(rotatedImageRef);
	CGContextRelease(bmpContext);
    
	return rotated;
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    BOOL drawTransposed;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) {
        // Apprently in iOS 5 the image is already correctly rotated, so we don't need to rotate it manually
        drawTransposed = NO;
    } else {
        switch (self.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                drawTransposed = YES;
                break;
                
            default:
                drawTransposed = NO;
        }
        
        transform = [self transformForOrientation:newSize];
    }
    
    return [self resizedImage:newSize
                    transform:transform
               drawTransposed:drawTransposed
         interpolationQuality:quality];
}

#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                kCGImageAlphaPremultipliedFirst);
    
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }
    
    return transform;
}
@end
