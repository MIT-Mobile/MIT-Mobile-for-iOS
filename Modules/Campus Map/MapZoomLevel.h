#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SaveOperation.h"

@interface MapTile : NSObject {
    NSString *_path;
    MKMapRect _frame;
}

@property (nonatomic, retain) NSString *path;
@property (nonatomic, assign) MKMapRect frame;

@end

@interface MapZoomLevel : NSObject <SaveOperationDelegate>
{
    NSInteger level;
    CGFloat resolution;
    CGFloat scale;
    NSInteger maxCol;
    NSInteger maxRow;
    NSInteger minCol;
    NSInteger minRow;
    MKZoomScale zoomScale;
    NSOperationQueue *_saveOperationQueue;
    
    BOOL requesting;
}

- (CGSize)totalSizeInPixels;
- (NSInteger)tilesPerRow;
- (NSInteger)tilesPerCol;

- (NSString *)pathForTileAtRow:(int)row col:(int)col;
- (NSArray *)tilesForMapRect:(MKMapRect)mapRect;

@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) CGFloat resolution;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) NSInteger maxCol;
@property (nonatomic, assign) NSInteger maxRow;
@property (nonatomic, assign) NSInteger minCol;
@property (nonatomic, assign) NSInteger minRow;
@property (nonatomic, assign) MKZoomScale zoomScale;

@end



