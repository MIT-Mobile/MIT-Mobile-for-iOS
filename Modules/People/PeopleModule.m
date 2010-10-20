#import "PeopleModule.h"

@implementation PeopleModule

- (id)init
{
    if (self = [super init]) {
        self.tag = DirectoryTag;
        self.shortName = @"Directory";
        self.longName = @"People Directory";
        self.iconName = @"people";

		viewController = [[[PeopleSearchViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		viewController.navigationItem.title = self.longName;
        
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:viewController]];
    }
    return self;
}


/*
- (void)applicationDidFinishLaunching
{
}
*/

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
    if ([localPath isEqualToString:@"search"] && [query length] > 0) {
        // make sure search happens from root view of directory
        [viewController.navigationController popToRootViewControllerAnimated:NO];
        [viewController beginExternalSearch:query];
        [self becomeActiveTab];
        didHandle = YES;
    }
    return didHandle;
}


- (void)dealloc
{
	[super dealloc];
}


@end

