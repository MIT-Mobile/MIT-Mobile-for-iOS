#import "MapTileOverlay.h"
#import "MITProjection.h"
#import "MapZoomLevel.h"

@implementation MapTileOverlay

- (id)init {
    self = [super init];
    if (self) {
        CLLocationCoordinate2D nw = [[MITMKProjection sharedProjection] northWestBoundary];
        CLLocationCoordinate2D se = [[MITMKProjection sharedProjection] southEastBoundary];
        MKMapPoint mapNW = MKMapPointForCoordinate(nw);
        MKMapPoint mapSE = MKMapPointForCoordinate(se);
        boundingMapRect = MKMapRectMake(mapNW.x, mapSE.y, mapSE.x - mapNW.x, mapNW.y - mapSE.y);
        coordinate = CLLocationCoordinate2DMake((nw.latitude + se.latitude) / 2, (nw.longitude + se.longitude) / 2);
    }
    return self;
}


- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (MKMapRect)boundingMapRect {
    return boundingMapRect;
}

//- (BOOL)intersectsMapRect:(MKMapRect)mapRect

+ (NSString*)pathForTileAtLevel:(int)level row:(int)row col:(int)col {
	NSString* tileCachePath = [MITMKProjection tileCachePath];
	return [tileCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%d/%d", level, row, col]];
}

@end


@implementation MapTileOverlayView

- (id)initWithOverlay:(id <MKOverlay>)overlay {
    self = [super initWithOverlay:overlay];
    return self;
}


// don't draw above certain zoomscale and outside certain maprect
- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
    return (zoomScale >= [[MITMKProjection sharedProjection] minimumZoomScale]
            && zoomScale <= [[MITMKProjection sharedProjection] maximumZoomScale]
            && MKMapRectIntersectsRect(mapRect, [[MITMKProjection sharedProjection] mapRectForFullExtent]));
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    
    NSArray *zoomLevels = [[MITMKProjection sharedProjection] mapLevels];
    MapZoomLevel *theZoomLevel = nil;
    CGFloat scale = 0.0;
    // TODO: find a more efficient way to get zoomLevel
    for (theZoomLevel in zoomLevels) {
        // keep iterating until we reach the max scale, or hit one scale larger
        scale = theZoomLevel.zoomScale;
        if (scale >= zoomScale) {
            break;
        }
    }
    
    NSArray *tiles = [theZoomLevel tilesForMapRect:mapRect];

    for (MapTile *tile in tiles) {
        CGRect rect = [self rectForMapRect:tile.frame];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:tile.path];
        if (image == nil) {
            VLog(@"image is nil");
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:tile.path error:&error];
        } else {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            CGContextScaleCTM(context, 1/zoomScale, 1/zoomScale);
            CGContextTranslateCTM(context, 0, image.size.height);
            CGContextScaleCTM(context, 1, -1);
            CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
            CGContextRestoreGState(context);
        }
        [image release];
    }
}


/*
 - (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect
 - (void)setNeedsDisplayInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
 */

@end