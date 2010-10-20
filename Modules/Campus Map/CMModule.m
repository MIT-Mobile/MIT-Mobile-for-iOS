#import "CMModule.h"
#import "CampusMapViewController.h"
//#import "MITMapViewController.h"

@implementation CMModule
@synthesize campusMapVC = _campusMapVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CampusMapTag;
        self.shortName = @"Map";
        self.longName = @"Campus Map";
        self.iconName = @"map";
       
		self.campusMapVC = [[[CampusMapViewController alloc] init] autorelease];
		self.campusMapVC.title = @"Campus Map";
											
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:self.campusMapVC]];
    }
    return self;
}

-(void) dealloc
{
	self.campusMapVC = nil;
	
	[super dealloc];
}
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
	if ([localPath isEqualToString:@"search"])
	{
        self.campusMapVC.view;
        
		// populate search bar
		self.campusMapVC.searchBar.text = query;
		
		// perform the search
		[self.campusMapVC search:query];
		
		// make sure the campus map is the root view controller
		[self.tabNavController popToViewController:self.campusMapVC
										  animated:NO];

		// make sure the map is the active bar
		[self becomeActiveTab];
        
		return YES;
	}
	
	return NO;
}

@end
