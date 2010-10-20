
#import "MITSearchEffects.h"
#import "MIT_MobileAppDelegate.h"


@implementation MITSearchEffects

@dynamic controller;

-(id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	}
	return self;
}

- (UIViewController *)controller {
	return theController;
}

- (void)setController:(UIViewController *)controller {
	theController = nil;
	theController = controller;
	if ([theController respondsToSelector:@selector(cancelSearch)]) {
		[self addTarget:theController action:@selector(cancelSearch) forControlEvents:UIControlEventTouchDown];
	}
}

- (void)dealloc {
	[super dealloc];
}

+ (MITSearchEffects *) overlayForTableviewController: (UITableViewController *)controller {
	CGFloat headerHeight = controller.tableView.tableHeaderView.frame.size.height;
	MITSearchEffects *searchBackground = [[MITSearchEffects alloc] initWithFrame:CGRectMake(0.0, headerHeight, controller.tableView.frame.size.width, 
																		controller.tableView.frame.size.height - headerHeight)];
	[searchBackground setController:controller];
	return [searchBackground autorelease];
}

+ (CGRect) frameWithHeader: (UIView *)headerView {
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];

    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGFloat y = headerView.frame.size.height;
    CGFloat height = appFrame.size.height - y - appDelegate.tabBarController.tabBar.frame.size.height;

	return CGRectMake(0.0, y, appFrame.size.width, height);
}

@end
