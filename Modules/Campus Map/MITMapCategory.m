
#import "MITMapCategory.h"
#import "MITMapSearchResultAnnotation.h"

@implementation MITMapCategory
@synthesize categoryName = _categoryName;
@synthesize categoryItems = _categoryItems;

-(void) dealloc
{
	self.categoryName = nil;
	
	[super dealloc];
}

-(id) initWithInfo:(NSDictionary*)info
{
	self = [super init];
	if (self) {
		self.categoryName = [info objectForKey:@"categoryName"];

		NSArray *categoryItems = [info objectForKey:@"categoryItems"];
		
		// make sure it is an array
		if ([categoryItems isKindOfClass:[NSArray class]]) 
		{
			  
			NSMutableArray* annotations = [NSMutableArray arrayWithCapacity:categoryItems.count];
			
			for (NSDictionary* item in categoryItems)
			{
				
				CLLocationCoordinate2D coordinate;
				
				coordinate.latitude = [[item objectForKey:@"lat"] doubleValue];
				coordinate.longitude = [[item objectForKey:@"lon"] doubleValue];
				
				MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithCoordinate:coordinate] autorelease];
				
				annotation.name = [item objectForKey:@"name"];
				annotation.bldgnum = [item objectForKey:@"building"];
				
				[annotations addObject:annotation]; 
			}
			
			
			self.categoryItems = annotations;
			 
		}
			 
	}
	
	return self;
}
@end
