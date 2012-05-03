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
@interface StellarMainTableController ()
@property (nonatomic, strong) NSString *doSearchTerms;
@property (nonatomic, strong) StellarSearch *stellarSearch;
@property (strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) MITSearchDisplayController *searchController;
@end

@implementation StellarMainTableController
{
	BOOL isViewAppeared;
	BOOL doSearchExecute;
}

@synthesize courseGroups = _courseGroups;
@synthesize myStellar = _myStellar;
@synthesize mainTableView = _mainTableView;
@synthesize loadingView = _loadingView;
@synthesize searchResultsTableView = _searchResultsTableView;
@synthesize myStellarUIisUpToDate = _myStellarUIisUpToDate;
@synthesize url = _url;
@synthesize searchBar = _searchBar;
@synthesize doSearchTerms = _doSearchTerms;
@synthesize stellarSearch = _stellarSearch;
@synthesize searchController = _searchController;

- (id) init {
	self = [super init];
	if (self) {
        self.title = @"MIT Stellar";
        
		_url = [[MITModuleURL alloc] initWithTag:StellarTag];
        
		isViewAppeared = NO;
	}
	return self;
}

- (void) dealloc {
	[_url release];
	[super dealloc];
}

- (void)loadView
{
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController.navigationBarHidden == NO)
    {
        mainFrame.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
        mainFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    }
    
    UIView *mainView = [[[UIView alloc] initWithFrame:mainFrame] autorelease];
    CGRect viewBounds = mainView.bounds;
    
    {
        CGRect searchFrame = CGRectZero;
        searchFrame.size.width = CGRectGetWidth(viewBounds);
        
        UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:searchFrame] autorelease];
        searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        searchBar.placeholder = @"Search by keyword or subject #";
        [searchBar sizeToFit];
        
        [mainView addSubview:searchBar];
        self.searchBar = searchBar;
        
        viewBounds.origin.y += CGRectGetHeight(searchBar.frame);
        viewBounds.size.height -= CGRectGetHeight(searchBar.frame);
    }
    
    {
        CGRect tableFrame = viewBounds;
        UITableView *mainTable = [[[UITableView alloc] initWithFrame:tableFrame
                                                               style:UITableViewStyleGrouped] autorelease];
        
        mainTable.delegate = self;
        mainTable.dataSource = self;
        mainTable.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);
        [mainTable applyStandardColors];
        
        [mainView addSubview:mainTable];
        self.mainTableView = mainTable;
    }
    
    {
        CGRect searchTableFrame = viewBounds;
        UITableView *searchTable = [[[UITableView alloc] initWithFrame:searchTableFrame
                                                                 style:UITableViewStylePlain] autorelease];
        searchTable.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                         UIViewAutoresizingFlexibleWidth);
        
        self.searchResultsTableView = searchTable;
    }
    
	self.loadingView = nil;
    
    self.view = mainView;
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
    self.courseGroups = [NSArray array];
    self.myStellar = [NSArray array];
    
	[self reloadMyStellarData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyStellarData) name:MyStellarChanged object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyStellarNotifications) name:MyStellarAlertNotification object:nil];
    
    
    StellarSearch *stellarSearch = [[[StellarSearch alloc] initWithSearchBar:self.searchBar
                                                             viewController:self] autorelease];
    self.searchResultsTableView.delegate = stellarSearch;
    self.searchResultsTableView.dataSource = stellarSearch;
    self.stellarSearch = stellarSearch;


    MITSearchDisplayController *searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                                                       contentsController:self] autorelease];
    searchController.delegate = self.stellarSearch;
    searchController.searchResultsTableView = self.searchResultsTableView;
    self.searchController = searchController;
	
	// load all course groups (asynchronously) in case it requires server access
	[StellarModel loadCoursesFromServerAndNotify:self];
	[StellarModel removeOldFavorites:self];

	self.doSearchTerms = nil;
}

- (void) viewDidUnload {
	self.searchBar = nil;
    self.searchResultsTableView = nil;
    self.doSearchTerms = nil;
	self.mainTableView.delegate = nil;
	self.mainTableView.dataSource = nil;
	self.mainTableView = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.loadingView = nil;
    self.courseGroups = nil;
    self.stellarSearch = nil;
    self.myStellar = nil;
	[super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
	isViewAppeared = YES;
	if (self.doSearchTerms) {
		[self doSearch:self.doSearchTerms execute:doSearchExecute];
	}
	[self.url setAsModulePath];
}

- (void) viewDidDisappear:(BOOL)animated {
	isViewAppeared = NO;
}

- (void) reloadMyStellarData {
	self.myStellar = [StellarModel myStellarClasses];
	if(![self.stellarSearch isSearchResultsVisible]) {
		[self.mainTableView reloadData];
		_myStellarUIisUpToDate = YES;
	} else {
		_myStellarUIisUpToDate = NO;
	}
}
	
- (void) reloadMyStellarNotifications {
	if([self.myStellar count]) {
		NSMutableArray *indexPaths = [NSMutableArray array];
		for (NSUInteger rowIndex=0; rowIndex < [self.myStellar count]; rowIndex++) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex inSection:myStellarGroup]];
		}
		if (self.mainTableView.dataSource) {
			[self.mainTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}
		
- (void) reloadMyStellarUI {
	if(_myStellarUIisUpToDate == NO) {
		[self.mainTableView reloadData];
	    _myStellarUIisUpToDate = YES;
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
	if([self.myStellar count]) {
		return 2;
	} else {
		return 1;
	}
}

- (NSInteger) groupIndexFromSectionIndex: (NSInteger)sectionIndex {
	if([self.myStellar count]) {
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
		myStellarClass = (StellarClass *)[self.myStellar objectAtIndex:indexPath.row];
		cell.textLabel.text = myStellarClass.name;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
		// check if the class has an unread notice
		if([MITUnreadNotifications hasUnreadNotification:[[[MITNotification alloc] initWithModuleName:StellarTag noticeId:myStellarClass.masterSubjectId] autorelease]]) {
			cell.imageView.image = [UIImage imageNamed:@"global/unread-message.png"];
		} else {
			cell.imageView.image = nil;
		}
	} else if(groupIndex == browseGroup) {
		cell.textLabel.text = ((StellarCourseGroup *)[self.courseGroups objectAtIndex:indexPath.row]).title;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = nil;
	}
	return cell;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	NSInteger groupIndex = [self groupIndexFromSectionIndex:section];
	if(groupIndex == myStellarGroup) {
		return [self.myStellar count];
	} else if(groupIndex == browseGroup) {
		return [self.courseGroups count];
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
			launchClass:(StellarClass *)[self.myStellar objectAtIndex:indexPath.row]
			viewController: self];
	} else if(groupIndex == browseGroup) {
		[self.navigationController
			pushViewController: [[[StellarCoursesTableController alloc] 
				initWithCourseGroup: (StellarCourseGroup *)[self.courseGroups objectAtIndex:indexPath.row]] autorelease]
			animated:YES];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) searchOverlayTapped {
	[self.stellarSearch endSearchMode];
}

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute {
	if(isViewAppeared) {
		self.searchBar.text = searchTerms;
		if (execute) {
			self.searchBar.text = searchTerms;
			[self.stellarSearch performSelector:@selector(searchBarSearchButtonClicked:)
                                     withObject:self.searchBar
                                     afterDelay:0.3];
		} else {
			// using a delay gets rid of a mysterious wait_fences warning
			[self.searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
		}
		self.doSearchTerms = nil;
	} else {
		// since view has not appeared yet, this search needs to be delay to either viewWillAppear or viewDidAppear
		// this is a work around for funky behavior when module is in the more list controller
		self.doSearchTerms = searchTerms;
		doSearchExecute = execute;
	}
}

- (void) showSearchResultsTable {
	self.mainTableView.delegate = nil;
	self.mainTableView.dataSource = nil;
	[self.view addSubview:self.searchResultsTableView];
}

- (void) showLoadingView {
	if (!self.loadingView) {
		self.loadingView = [[[MITLoadingActivityView alloc] 
		  initWithFrame:CGRectMake(0,
                                   self.searchBar.frame.size.height,
                                   self.view.frame.size.width,
                                   self.view.frame.size.height - self.searchBar.frame.size.height)]
		 autorelease];
	}
	[self.view addSubview:self.loadingView];
}

- (void) hideSearchResultsTable {
	[self.searchResultsTableView removeFromSuperview];
	self.mainTableView.delegate = self;
	self.mainTableView.dataSource = self;
}

- (void) hideLoadingView {
	[self.loadingView removeFromSuperview];
}

@end
