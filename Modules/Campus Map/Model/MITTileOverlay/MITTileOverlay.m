#import "MITTileOverlay.h"

static NSString * const kMITTileOverlayParentDirectoryName = @"MITMapTiles";

@implementation MITTileOverlay

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *, NSError *))result
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *resourceName = [NSString stringWithFormat:@"%li", (long)path.x];
    NSString *tilePath = [mainBundle pathForResource:resourceName ofType:nil inDirectory:[self localDirectoryForOverlayPath:path]];
    if (tilePath) {
        NSError *err;
        NSData *data = [NSData dataWithContentsOfFile:tilePath options:0 error:&err];
        result(data, err);
    } else {
        [super loadTileAtPath:path result:result];
    }
}

- (NSString *)localDirectoryForOverlayPath:(MKTileOverlayPath)overlayPath
{
    NSMutableString *directoryPath = [NSMutableString stringWithString:kMITTileOverlayParentDirectoryName];
    [directoryPath appendFormat:@"/%li", (long)overlayPath.z];
    [directoryPath appendFormat:@"/%li", (long)overlayPath.y];
    return directoryPath;
}

@end
