#import "StellarClassesTableController.h"
#import "StellarCoursesTableController.h"
#import "StellarDetailViewController.h"
#import "StellarClassTableCell.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"
#import "MultiLineTableViewCell.h"


@interface StellarClassesTableController (Private)
- (void) alertViewCancel: (UIAlertView *)alertView;
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex;
@end

@implementation StellarClassesTableController
@synthesize classes, currentClassLoader;
@synthesize loadingView;
@synthesize url;

- (id) initWithCourse: (StellarCourse *)aCourse {
    self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		course = [aCourse retain];
		classes = [[NSArray array] retain];
		loadingView = nil;
		url = [[MITModuleURL alloc] initWithTag:StellarTag];
	}
	return self;
}

- (void) dealloc {
	currentClassLoader.tableController = nil;
	[url release];
	[loadingView release];
	[currentClassLoader release];
	[classes release];
	[course release];
	[super dealloc];
}

- (void) showLoadingView {
	self.tableView.tableHeaderView = loadingView;
	self.tableView.backgroundColor = [UIColor clearColor];
}

- (void) hideLoadingView {
	self.tableView.tableHeaderView = nil;
	self.tableView.backgroundColor = [UIColor whiteColor];
}
	
- (void) viewDidLoad {
    [MultiLineTableViewCell setNeedsRedrawing:YES];
    
	self.title = [@"Course " stringByAppendingString:course.number];
	self.currentClassLoader = [[LoadClassesInTable new] autorelease];
	self.currentClassLoader.tableController = self;
	
	[self.tableView applyStandardCellHeight];
	
    CGRect loadingFrame = [MITAppDelegate() rootNavigationController].view.bounds;
	self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
	
	[self showLoadingView];
	
	[StellarModel loadClassesForCourse:course delegate:self.currentClassLoader];
	
	[url setPathWithViewController:self
                         extension:course.number];
}

- (void) viewDidAppear: (BOOL)animated {
	[url setAsModulePath];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	StellarClassTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarClasses"];
	if(cell == nil) {
        cell = [[[StellarClassTableCell alloc] initWithReuseIdentifier:@"StellarClasses"] autorelease];
	}

    cell.stellarClass = [classes objectAtIndex:indexPath.row];
    return cell;
}	

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [classes count];
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[StellarDetailViewController 
		launchClass:(StellarClass *)[classes objectAtIndex:indexPath.row]
		viewController: self];
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	static StellarClassTableCell *calcCell = nil;

    if (calcCell == nil)
    {
        calcCell = [[StellarClassTableCell alloc] init];
    }

    calcCell.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 44.0f);
    calcCell.stellarClass = [classes objectAtIndex:indexPath.row];
    [calcCell layoutSubviews];

    CGSize fitSize = [calcCell sizeThatFits:calcCell.contentView.bounds.size];
    return fitSize.height;
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) alertViewCancel: (UIAlertView *)alertView {
	[self.navigationController popViewControllerAnimated:YES];
}
	
@end


@implementation LoadClassesInTable
@synthesize tableController;

- (void) classesLoaded: (NSArray *)aClassList {
	if(tableController.currentClassLoader == self) {
		tableController.classes = aClassList;
		[tableController hideLoadingView];
		[tableController.tableView reloadData];
	}
}

- (void) handleCouldNotReachStellar {
	if(tableController.currentClassLoader == self) {
		[tableController hideLoadingView];
	}
}

- (id<UIAlertViewDelegate>) standardErrorAlertDelegate {
	if(tableController.currentClassLoader == self) {
		return tableController;
	} else {
		return nil;
	}
}
	
@end
