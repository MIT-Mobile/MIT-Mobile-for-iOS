
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
@synthesize info = _info;
@synthesize bookmark = _bookmark;

+(void) executeServerSearchWithQuery:(NSString *)query jsonDelegate:(id<JSONLoadedDelegate>)delegate object:(id)object {
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI jsonLoadedDelegate:delegate];
	apiRequest.userData = object;
	[apiRequest requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"search", @"command", query, @"q", nil]
				pathExtension:@"map/"];
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
	self.info = nil;
	
	[super dealloc];
}

-(id) initWithInfo:(NSDictionary*)info
{
	self = [super init];
	if (self) {
		self.info = info;
		
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

-(NSDictionary*) info
{
	// if there is a dictionary of info, return it. Otherwise construct the dictionary based on what we do have. 
	if(nil != _info)
		return _info;
	
	NSMutableDictionary* info = [NSMutableDictionary dictionary];
	if (nil == self.architect)	[info setObject:self.architect	forKey:@"architect"];
	if (nil == self.bldgimg)		[info setObject:self.bldgimg	forKey:@"bldgimg"];
	if (nil == self.bldgnum)		[info setObject:self.bldgnum	forKey:@"bldgnum"];
	if (nil == self.uniqueID)	[info setObject:self.uniqueID	forKey:@"id"];
	if (nil == self.mailing)		[info setObject:self.mailing	forKey:@"mailing"];
	if (nil == self.name)		[info setObject:self.name		forKey:@"name"];
	if (nil == self.street)		[info setObject:self.street		forKey:@"street"];
	if (nil == self.viewAngle)	[info setObject:self.viewAngle	forKey:@"viewangle"];
	if (nil == self.city)		[info setObject:self.city		forKey:@"city"];
	
	[info setObject:[NSNumber numberWithDouble:_coordinate.latitude]	forKey:@"lat_wgs84"];
	[info setObject:[NSNumber numberWithDouble:_coordinate.longitude]	forKey:@"long_wgs84"];
	
	if(nil != self.contents)
	{
		NSMutableArray* contents = [NSMutableArray arrayWithCapacity:self.contents.count];
		for (NSString* content in self.contents) {
			[contents addObject:[NSDictionary dictionaryWithObject:content forKey:@"name"]];
		}
		
		[info setObject:contents forKey:@"contents"];
	}

	if(nil != self.snippets) [info setObject:self.snippets forKey:@"snippets"];
	
	return info;
	
	
}
-(id) initWithCoordinate:(CLLocationCoordinate2D) coordinate
{
	self = [super init];
	if (self) {
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
