
#import <Foundation/Foundation.h>


@interface MapTileExtent : NSObject {

	int _minRow;
	int _minCol;
	int _maxRow;
	int _maxCol;
	
}

@property int minRow;
@property int maxRow;
@property int minCol;
@property int maxCol;

@property (readonly) int rows;
@property (readonly) int cols;

// initialize the extent with the tile bounds
-(id) initWithMinRow:(int)minRow minCol:(int)minCol maxRow:(int)maxRow maxCol:(int)maxCol;

@end
