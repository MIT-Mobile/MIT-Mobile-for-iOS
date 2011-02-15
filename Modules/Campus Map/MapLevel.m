
#import "MapLevel.h"


@implementation MapLevel
@synthesize level  = _level;

-(void) dealloc
{
	[super dealloc];
}

-(id) initWithLevel:(int)level minRow:(int)minRow minCol:(int)minCol maxRow:(int)maxRow maxCol:(int)maxCol;
{
	self = [super initWithMinRow:minRow minCol:minCol maxRow:maxRow maxCol:maxCol ];
	if (self) {
		self.level = level;
	}
	
	return self;
}

+(id) levelWithInfo:(NSDictionary*)levelInfo
{
	MapLevel* level = [[[MapLevel alloc] initWithLevel:[[levelInfo objectForKey:kLevel] intValue]
												  minRow:[[levelInfo objectForKey:kMinRow] intValue]
						 						  minCol:[[levelInfo objectForKey:kMinCol] intValue]
												  maxRow:[[levelInfo objectForKey:kMaxRow] intValue]
												  maxCol:[[levelInfo objectForKey:kMaxCol] intValue]] autorelease];
	
	return level;
}

@end
