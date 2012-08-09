#import "QRReaderResult.h"
#import "MITScannerImage.h"

@interface QRReaderResult ()
@property (nonatomic, retain) MITScannerImage *imageData;
@property (nonatomic, retain) UIImage *image;
@end

@implementation QRReaderResult
@dynamic date;
@dynamic thumbnail;
@dynamic text;
@dynamic imageData;
@dynamic image;

+ (CGSize)defaultThumbnailSize
{
    return CGSizeMake(78,78);
}

- (UIImage*)scanImage
{
    if (self.image)
    {
        // Looks like we are using an older version of the schema.
        // Store a pointer to the old image in the new ivar
        // and mark it as being changed so it will persist through the next
        // save.
        
        self.scanImage = self.image;
        self.image = nil;
    }
    else if (self.imageData)
    {
        return self.imageData.image;
    }
    
    return nil;
}

- (void)setScanImage:(UIImage *)image
{
    if (self.imageData == nil)
    {
        MITScannerImage *imageData = [NSEntityDescription insertNewObjectForEntityForName:@"MITScannerImage"
                                                               inManagedObjectContext:[self managedObjectContext]];
        imageData.image = image;
        self.imageData = imageData;
    }
    else
    {
        self.imageData.image = image;
    }
}

@end
