#import "PeopleModule.h"
#import "MITModuleURL.h"
#import "PeopleSearchViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PersonDetails.h"



static NSString * const PeopleStateSearchBegin = @"search-begin";
static NSString * const PeopleStateSearchComplete = @"search-complete";
static NSString * const PeopleStateSearchExternal = @"search";
static NSString * const PeopleStateDetail = @"detail";

@interface PeopleModule()

@property (nonatomic,readonly) PeopleSearchViewController *peopleController;

@end

@implementation PeopleModule

@synthesize peopleController = _peopleController;

- (id)init
{
    self = [super init];
    if (self) {
        self.tag = DirectoryTag;
        self.shortName = @"Directory";
        self.longName = @"People Directory";
        self.iconName = @"people";
    }
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"People" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    _peopleController = [storyboard instantiateInitialViewController];
    
    return _peopleController;
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"People_iPad" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    _peopleController = [storyboard instantiateInitialViewController];
    
    return _peopleController;
}

- (void)applicationWillTerminate
{
	MITModuleURL *url = [[MITModuleURL alloc] initWithTag:DirectoryTag];
	
	UIViewController *visibleVC = self.peopleController.navigationController.visibleViewController;
	if ([visibleVC isMemberOfClass:[PeopleSearchViewController class]]) {
		PeopleSearchViewController *searchVC = (PeopleSearchViewController *)visibleVC;
		if (searchVC.searchDisplayController.active) {
            [url setPath:PeopleStateSearchBegin query:searchVC.searchBar.text];
        } else if ([searchVC searchResults] != nil) {
            [url setPath:PeopleStateSearchComplete query:searchVC.searchBar.text];
		} else {
			[url setPath:nil query:nil];
		}

	} else if ([visibleVC isMemberOfClass:[PeopleDetailsViewController class]]) {
		PeopleDetailsViewController *detailVC = (PeopleDetailsViewController *)visibleVC;
		[url setPath:PeopleStateDetail query:detailVC.personDetails.uid];
	}
	
	[url setAsModulePath];
}


- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
    BOOL pushHomeController = YES;
    
    if (self.peopleController.view == nil) {
        DDLogError(@"Failed to load view controller for tag %@ in '%@'", self.tag, NSStringFromSelector(_cmd));
    }
 
	if (localPath == nil) {
		didHandle = YES;
	} 
	else if ([localPath isEqualToString:PeopleStateSearchBegin])
    {
		if (query != nil) {
			self.peopleController.searchBar.text = query;
		}

        [self.peopleController.searchDisplayController setActive:YES animated:NO];
        didHandle = YES;
	} else if (!query || [query length] == 0) {
		// from this point forward we don't want to handle anything
		// without proper query terms
		didHandle = NO;
	} else if ([localPath isEqualToString:PeopleStateSearchComplete]) {
        [self.peopleController beginExternalSearch:query];
		didHandle = YES;
	} else if ([localPath isEqualToString:PeopleStateSearchExternal]) {
		// this path is reserved for calling from other modules
		// do not save state with this path       
        [self.peopleController beginExternalSearch:query];
        didHandle = YES;
	} else if ([localPath isEqualToString:PeopleStateDetail]) {
		PersonDetails *person = [PeopleRecentsData personWithUID:query];
		if (person != nil) {
			PeopleDetailsViewController *detailVC = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
			detailVC.personDetails = person;
			[[MITAppDelegate() rootNavigationController] pushViewController:detailVC
                                                                   animated:NO];
			didHandle = YES;
            pushHomeController = NO;
		}
	}
    
    if (didHandle && pushHomeController) {
        [[MIT_MobileAppDelegate applicationDelegate] showModuleWithTag:self.tag];
    }
	
    return didHandle;
}

@end

