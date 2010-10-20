
#import "MITMapSearchResultAnnotation.h"


@implementation MITMapSearchResultAnnotation
@synthesize coordinate = _coordinate;
@synthesize architect = _architect;
@synthesize bldgimg = _bldgimg;
@synthesize bldgnum = _bldgnum;
@synthesize uniqueID = _uniqueID;
@synthesize mailing = _mailing;
@synthesize name = _name;
@synthesize street = _street;
@synthesize viewAngle = _viewAngle;
@synthesize contents = _contents;
@synthesize dataPopulated = _dataPopulated;
@synthesize snippets = _snippets;
@synthesize city = _city;

+(NSString*) urlSearchString
{
	return [NSString stringWithFormat:@"%@map/?command=search&q=%%@", MITMobileWebAPIURLString];
}

-(void) dealloc
{
	self.architect = nil;
	self.bldgnum = nil;
	self.bldgimg = nil;
	self.uniqueID = nil;
	self.mailing = nil;
	self.name = nil;
	self.street = nil;
	self.viewAngle = nil;
	self.contents = nil;
	self.snippets = nil;
	self.city = nil;
	
	[super dealloc];
}

-(id) initWithInfo:(NSDictionary*)info
{
	if(self = [super init])
	{
		self.architect = [info objectForKey:@"architect"];
		self.bldgimg =   [info objectForKey:@"bldgimg"];
		self.bldgnum =   [info objectForKey:@"bldgnum"];
		self.uniqueID =  [info objectForKey:@"id"];
		self.mailing  =  [info objectForKey:@"mailing"];
		self.name =      [info objectForKey:@"name"];
		self.street =    [info objectForKey:@"street"];
		self.viewAngle = [info objectForKey:@"viewangle"];
		self.city = [info objectForKey:@"city"];
		
		_coordinate.latitude = [[info objectForKey:@"lat_wgs84"] doubleValue];
		_coordinate.longitude = [[info objectForKey:@"long_wgs84"] doubleValue];
		
		
		NSArray* contents = [info objectForKey:@"contents"];
		NSMutableArray* contentsArr = [NSMutableArray arrayWithCapacity:contents.count];
		for (NSDictionary* contentInfo in contents)
		{
			NSString* content = [contentInfo objectForKey:@"name"];
			if(nil != content)
				[contentsArr addObject:content];
		}
		
		self.contents = contentsArr;
		self.snippets = [info objectForKey:@"snippets"];
		
		self.dataPopulated = YES;
	}
	
	return self;
	
}

-(id) initWithCoordinate:(CLLocationCoordinate2D) coordinate
{
	if(self = [super init])
	{
		_coordinate = coordinate;
	}
	
	return self;
}

#pragma mark MKAnnotation
-(NSString*) title
{
	if (nil == self.name && nil != self.bldgnum) 
	{
		return [NSString stringWithFormat:@"Building %@", self.bldgnum];
	}
	else if(nil != self.name && nil != self.bldgnum)
	{
		NSString* buildingName = [NSString stringWithFormat:@"Building %@", self.bldgnum];
		if ([buildingName isEqualToString:self.name]) {
			return self.name;
		}
		
		return [NSString stringWithFormat:@"%@ (%@)", buildingName, self.name];
	}
	else if(nil != self.name)
	{
		return self.name;
	}
	
	
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}
@end
