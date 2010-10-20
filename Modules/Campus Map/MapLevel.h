
#import <Foundation/Foundation.h>
#import "MapTileExtent.h"

#define kMinRow @"minRow"
#define kMaxRow @"maxRow"
#define kMinCol @"minCol"
#define kMaxCol @"maxCol"
#define kLevel  @"level"

@interface MapLevel : MapTileExtent {

	int _level;

}

@property int level;

// initialize the level with the level number and its tile bounds
-(id) initWithLevel:(int)level minRow:(int)minRow minCol:(int)minCol maxRow:(int)maxRow maxCol:(int)maxCol;

// returns an autoreleased map level initialized with the contents of the dictionary
+(id) levelWithInfo:(NSDictionary*)levelInfo;


@end
