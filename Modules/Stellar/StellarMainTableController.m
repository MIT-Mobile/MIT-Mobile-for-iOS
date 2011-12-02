#import "StellarModule.h"
#import "StellarMainTableController.h"
#import "StellarCoursesTableController.h"
#import "StellarDetailViewController.h"
#import "StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "UIKit+MITAdditions.h"
#import "MITConstants.h"
#import "MITUIConstants.h"
#import "MITLoadingActivityView.h"
#import "MITModuleURL.h"

#define myStellarGroup 0
#define browseGroup 1

#define searchBarHeight NAVIGATION_BAR_HEIGHT
@interface StellarMainTableController(Private)
@property (nonatomic, retain) NSString *doSearchTerms;
@end

@implementation StellarMainTableController

@synthesize courseGroups, myStellar;
@synthesize mainTableView;
@synthesize loadingView, searchResultsTableView;
@synthesize myStellarUIisUpToDate;
@synthesize url;
@synthesize searchBar;

- (id) init {
	self = [super init];
	if (self) {
		url = [[MITModuleURL alloc] initWithTag:StellarTag];
		isViewAppeared = NO;
	}
	return self;
}

- (void) dealloc {
	[url release];
	[super dealloc];
}

- (void) viewDidLoad {
	[super viewDidLoad];
    self.title = @"MIT Stellar";
    
	self.mainTableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, searchBarHeight, self.view.frame.size.width, self.view.frame.size.height-searchBarHeight) style:UITableViewStyleGrouped] autorelease];
	self.mainTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.mainTableView.delegate = self;
	self.mainTableView.dataSource = self;
	[self.view addSubview:self.mainTableView];
	[self.mainTableView applyStandardColors];
	
	// initialize with an empty array, to be replaced with data when available
	self.courseGroups = [NSArray array];
	self.myStellar = [NSArray array];
	
	CGRect viewFrame = self.view.frame;
	self.searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, searchBarHeight)] autorelease];
	searchBar.tintColor = SEARCH_BAR_TINT_COLOR;	
	[self.view addSubview:searchBar];	
	
	CGRect frame = CGRectMake(0.0, searchBar.frame.size.height, searchBar.frame.size.width, self.view.frame.size.height - searchBar.frame.size.height);
    searchResultsTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];

	stellarSearch = [[StellarSearch alloc] initWithSearchBar:searchBar viewController:self];	
	searchResultsTableView.delegate = stellarSearch;
	searchResultsTableView.dataSource = stellarSearch;
	
	searchBar.placeholder = @"Search by keyword or subject #";
    searchController = [[MITSearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchController.delegate = stellarSearch;
    searchController.searchResultsTableView = searchResultsTableView;
	 
	self.loadingView = nil;
	
	[self reloadMyStellarData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyStellarData) name:MyStellarChanged object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyStellarNotifications) name:MyStellarAlertNotification object:nil];
	
	// load all course groups (asynchronously) in case it requires server access
	[StellarModel loadCoursesFromServerAndNotify:self];
	
	[StellarModel removeOldFavorites:self];
	
	self.doSearchTerms = nil;
	
	//translucentOverlayActive = NO;
}

- (void) viewDidUnload {
	self.searchBar = nil;
	[searchResultsTableView release];
	[doSearchTerms release];
	self.mainTableView.delegate = nil;
	self.mainTableView.dataSource = nil;
	self.mainTableView = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[myStellar release];
	[courseGroups release];
	[stellarSearch release];
	
	[loadingView release];
	[super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
	isViewAppeared = YES;
	if (doSearchTerms) {
		[self doSearch:doSearchTerms execute:doSearchExecute];
	}
	[url setAsModulePath];
}

- (void) viewDidDisappear:(BOOL)animated {
	isViewAppeared = NO;
}

- (void) reloadMyStellarData {
	self.myStellar = [StellarModel myStellarClasses];
	if(![stellarSearch isSearchResultsVisible]) {
		[self.mainTableView reloadData];
		myStellarUIisUpToDate = YES;
	} else {
		myStellarUIisUpToDate = NO;
	}
}
	
- (void) reloadMyStellarNotifications {
	if(myStellar.count) {
		NSMutableArray *indexPaths = [NSMutableArray array];
		for (NSUInteger rowIndex=0; rowIndex < myStellar.count; rowIndex++) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex inSection:myStellarGroup]];
		}
		if (self.mainTableView.dataSource) {
			[self.mainTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}
		
- (void) reloadMyStellarUI {
	if(!myStellarUIisUpToDate) {
		[self.mainTableView reloadData];
	    myStellarUIisUpToDate = YES;
	}
}

- (void) classesRemoved: (NSArray *)classes {
	NSString *message = @"The following old classes have been removed from your My Stellar settings:";
	BOOL firstId = YES;
	for(StellarClass *class in classes) {
		if(firstId) {
			firstId = NO;
			message = [message stringByAppendingString:@" "];
		} else {
			message = [message stringByAppendingString:@", "];
		}
		message = [message stringByAppendingString:class.masterSubjectId];
	}
	
	UIAlertView *alertView = [[UIAlertView alloc]
		initWithTitle:@"Old Classes" 
		message:message delegate:nil 
		cancelButtonTitle:@"OK" 
		otherButtonTitles:nil];
	
	[alertView show];
	[alertView release];
}

- (void) coursesLoaded {
	self.courseGroups = [StellarCourseGroup allCourseGroups:[StellarModel allCourses]];
	[self.mainTableView reloadData];
}

// "DataSource" methods
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	if([myStellar count]) {
		return 2;
	} else {
		return 1;
	}
}

- (NSInteger) groupIndexFromSectionIndex: (NSInteger)sectionIndex {
	if([myStellar count]) {
		return sectionIndex;
	} else if(sectionIndex == 0) {
		return browseGroup;
	}
	
	return -1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarMain"];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StellarMain"] autorelease];
		[cell applyStandardFonts];
	}
	
	StellarClass *myStellarClass;
	NSInteger groupIndex = [self groupIndexFromSectionIndex:indexPath.section];
	if(groupIndex == myStellarGroup) {
		myStellarClass = (StellarClass *)[myStellar objectAtIndex:indexPath.row];
		cell.textLabel.text = myStellarClass.name;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
		// check if the class has an unread notice
		if([MITUnreadNotifications hasUnreadNotification:[[[MITNotification alloc] initWithModuleName:StellarTag noticeId:myStellarClass.masterSubjectId] autorelease]]) {
			cell.imageView.image = [UIImage imageNamed:@"global/unread-message.png"];
		} else {
			cell.imageView.image = nil;
		}
	} else if(groupIndex == browseGroup) {
		cell.textLabel.text = ((StellarCourseGroup *)[courseGroups objectAtIndex:indexPath.row]).title;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = nil;
	}
	return cell;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	NSInteger groupIndex = [self groupIndexFromSectionIndex:section];
	if(groupIndex == myStellarGroup) {
		return [myStellar count];
	} else if(groupIndex == browseGroup) {
		return [courseGroups count];
	}
	return 0;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	// TODO: determine if there is any benefit to optimizing this
	NSInteger groupIndex = [self groupIndexFromSectionIndex:section];
	NSString *headerTitle = nil;
	if(groupIndex == myStellarGroup) {
		headerTitle = @"My Stellar:";
	} else if(groupIndex == browseGroup) {
		headerTitle = @"Browse By Course:";
	}
	return [UITableView groupedSectionHeaderWithTitle:headerTitle];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	NSInteger groupIndex = [self groupIndexFromSectionIndex:indexPath.section];
	if(groupIndex == myStellarGroup) {
		[StellarDetailViewController
			launchClass:(StellarClass *)[myStellar objectAtIndex:indexPath.row]
			viewController: self];
	} else if(groupIndex == browseGroup) {
		[self.navigationController
			pushViewController: [[[StellarCoursesTableController alloc] 
				initWithCourseGroup: (StellarCourseGroup *)[courseGroups objectAtIndex:indexPath.row]] autorelease]
			animated:YES];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) searchOverlayTapped {
	[stellarSearch endSearchMode];
}

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute {
	if(isViewAppeared) {
		searchBar.text = searchTerms;
		if (execute) {
			searchBar.text = searchTerms;
			[stellarSearch performSelector:@selector(searchBarSearchButtonClicked:) withObject:searchBar afterDelay:0.3];
		} else {
			// using a delay gets rid of a mysterious wait_fences warning
			[searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
		}
		self.doSearchTerms = nil;
	} else {
		// since view has not appeared yet, this search needs to be delay to either viewWillAppear or viewDidAppear
		// this is a work around for funky behavior when module is in the more list controller
		self.doSearchTerms = searchTerms;
		doSearchExecute = execute;
	}
}

- (void) setDoSearchTerms:(NSString *)searhTerms {
	[doSearchTerms release];
	doSearchTerms = [searhTerms retain];
}

- (NSString *) doSearchTerms {
	return doSearchTerms;
}

- (void) showSearchResultsTable {
	self.mainTableView.delegate = nil;
	self.mainTableView.dataSource = nil;
	[self.view addSubview:searchResultsTableView];
}

- (void) showLoadingView {
	if (!loadingView) {
		self.loadingView = [[[MITLoadingActivityView alloc] 
		  initWithFrame:CGRectMake(0, searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height-searchBar.frame.size.height)]
		 autorelease];
	}
	[self.view addSubview:loadingView];
}

- (void) hideSearchResultsTable {
	[searchResultsTableView removeFromSuperview];
	self.mainTableView.delegate = self;
	self.mainTableView.dataSource = self;
}

- (void) hideLoadingView {
	[loadingView removeFromSuperview];
}

@end
