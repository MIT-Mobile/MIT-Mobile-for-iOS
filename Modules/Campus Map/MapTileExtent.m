
#import "MapTileExtent.h"


@implementation MapTileExtent
@synthesize minRow = _minRow;
@synthesize minCol = _minCol;
@synthesize maxRow = _maxRow;
@synthesize maxCol = _maxCol;

-(void) dealloc
{
	[super dealloc];
}

-(id) initWithMinRow:(int)minRow minCol:(int)minCol maxRow:(int)maxRow maxCol:(int)maxCol
{
	self = [super init];
	if (self) {
		self.minRow = minRow;
		self.minCol = minCol;
		self.maxRow = maxRow;
		self.maxCol = maxCol;
	}
	
	return self;
}

-(int) rows
{
	return self.maxRow - self.minRow;
}

-(int) cols
{
	return self.maxCol - self.minCol;
}

@end
