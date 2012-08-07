//
//  QRReaderResult.m
//  MIT Mobile
//
//  Created by Blake Skinner on 8/6/12.
//
//

#import "QRReaderResult.h"
#import "MITScannerImage.h"

@interface QRReaderResult ()
@property (nonatomic, retain) MITScannerImage *imageData;
@property (nonatomic, retain) UIImage *image;
@end

@implementation QRReaderResult
{
    BOOL _imageWasChanged;
    BOOL _thumbnailWasChanged;
}

@dynamic date;
@dynamic thumbnailData;
@dynamic text;
@dynamic imageData;
@dynamic scanOrientation;
@dynamic image;
@synthesize scanImage = _scanImage;
@synthesize thumbnail = _thumbnail;

+ (CGSize)defaultThumbnailSize
{
    return CGSizeMake(96,96);
}

- (UIImage*)scanImage
{
    if ((_scanImage == nil) && self.image)
    {
        // Looks like we are using an older version of the schema.
        // Store a pointer to the old image in the new ivar
        // and mark it as being changed so it will persist through the next
        // save.
        self.scanImage = self.image;
        self.image = nil;
    }
    else if ((_scanImage == nil) && self.imageData)
    {
        UIImage *image = [UIImage imageWithData:self.imageData.imageData];
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:1.0
                              orientation:(UIImageOrientation)[self.imageData.orientation integerValue]];
        self.scanImage = image;
        _imageWasChanged = NO;
    }
    
    return _scanImage;
}

- (void)setScanImage:(UIImage *)image
{
    [_scanImage release];
    _scanImage = [image retain];
    _imageWasChanged = YES;
    
    self.image = nil;
}

- (void)setThumbnail:(UIImage *)thumbnail
{
    [_thumbnail release];
    _thumbnail = [thumbnail retain];
    _thumbnailWasChanged = YES;
}

- (UIImage*)thumbnail
{
    if ((_thumbnail == nil) && self.thumbnailData)
    {
        self.thumbnail = [UIImage imageWithData:self.thumbnailData];
        _thumbnailWasChanged = NO;
    }
    
    return _thumbnail;
}

- (void)willSave
{
    // Persist the image if it has been changed
    if (_scanImage && _imageWasChanged)
    {
        MITScannerImage *imageData = self.imageData;
        
        if (imageData == nil)
        {
            imageData = [NSEntityDescription insertNewObjectForEntityForName:@"MITScannerImage"
                                                      inManagedObjectContext:[self managedObjectContext]];
        }
        
        self.imageData.imageData = UIImagePNGRepresentation(_scanImage);
        self.imageData.orientation = @(_scanImage.imageOrientation);
        self.scanOrientation = @(_scanImage.imageOrientation);
        
        _imageWasChanged = NO;
    }
    
    if (_thumbnailWasChanged)
    {
        if (_thumbnail)
        {
            self.thumbnailData = UIImagePNGRepresentation(_thumbnail);
        }
        else
        {
            self.thumbnailData = nil;
        }
        
        _thumbnailWasChanged = NO;
    }
}
@end
