#import "CategoriesTableViewController.h"
#import "MapSelectionController.h"
#import "MITMapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"

#define kAPICategoryTitles	@"CategoryTitles"
#define kAPICategory		@"Category"

@interface CategoriesTableViewController ()
@property (nonatomic,weak) MITLoadingActivityView *loadingView;
@end

@implementation CategoriesTableViewController

#pragma mark - Initialization


-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		_mapSelectionController = mapSelectionController;
	}
	
	return self;
}

-(id) initWithMapSelectionController:(MapSelectionController *)mapSelectionController andStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	if (self) {
		_mapSelectionController = mapSelectionController;
	}
	
	return self;
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    self.title = @"Browse";
	self.navigationItem.leftBarButtonItem.title = @"Back";
	self.navigationItem.rightBarButtonItem = self.mapSelectionController.cancelButton;
	
	if (self.topLevel) {
		self.headerText = @"Browse map by:";
        
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"map"
                                                                                command:@"categorytitles"
                                                                             parameters:nil];
        operation.userData = @"CategoryTitles";
        operation.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mime, NSError *error) {
            [self operation:operation
       didFinishWithContent:content
                   mimeType:mime
                      error:error];
        };
        
        [[NSOperationQueue mainQueue] addOperation:operation];

		if (!self.loadingView) {
			self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
			[self.view addSubview:loadingView];
            self.loadingView = loadingView;
		}
	}
	
	if(self.leafLevel)
	{
		if (!self.loadingView) {
			self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
			[self.view addSubview:loadingView];
            self.loadingView = loadingView;
		}
	}
	
	[self setToolbarItems:self.mapSelectionController.toolbarButtonItems];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.itemsInTable count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    }

    NSDictionary *item = self.itemsInTable[indexPath.row];

	if (item[@"categoryName"]) {
		cell.textLabel.text = [NSString stringWithFormat:@"%@",item[@"categoryName"]];
	} else {
		cell.textLabel.text = [NSString stringWithFormat:@"%@",item[@"displayName"]];
	}

	if (!self.leafLevel) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.backgroundColor = [UIColor whiteColor];
	}
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary* item = self.itemsInTable[indexPath.row];
	
	if (self.leafLevel) {
		
		// make sure the map is showing. 
		[self.mapSelectionController.mapVC showListView:NO];
		
		// clear the search bar
		self.mapSelectionController.mapVC.searchBar.text = @"";
		self.mapSelectionController.mapVC.lastSearchText = nil;
		
		NSMutableArray* searchResultsArray = [NSMutableArray array];

		MITMapSearchResultAnnotation* annotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:item];
		[searchResultsArray addObject:annotation];
		
		// this will remove any old annotations and add the new ones. 
		[self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
		
		// on the map, select the current annotation
		//[[self.mapSelectionController.mapVC mapView] selectAnnotation:annotation animated:NO withRecenter:YES];
		
		[self dismissModalViewControllerAnimated:YES];
	} else {
	
		CategoriesTableViewController* newCategoriesTVC = nil;
		
		if (item[@"subcategories"]) {
			newCategoriesTVC = [[CategoriesTableViewController alloc] initWithMapSelectionController:self.mapSelectionController];
			newCategoriesTVC.itemsInTable = item[@"subcategories"];

			NSString *formatString = @"Buildings by %@:";
            if ([item[@"categoryName"] isEqual:@"Building name"]) {
                newCategoriesTVC.headerText = [NSString stringWithFormat:formatString,@"name"];
            } else {
                newCategoriesTVC.headerText = [NSString stringWithFormat:formatString,@"number"];
            }
		} else {
			newCategoriesTVC = [[CategoriesTableViewController alloc] initWithMapSelectionController:self.mapSelectionController
                                                                                            andStyle:UITableViewStylePlain];
			[newCategoriesTVC executeServerCategoryRequestWithQuery:item[@"categoryId"]];
			newCategoriesTVC.leafLevel = YES;
			newCategoriesTVC.headerText = [NSString stringWithFormat:@"%@:", item[@"categoryName"]];
		}
		
		newCategoriesTVC.topLevel = NO;
		
		[self.navigationController pushViewController:newCategoriesTVC animated:YES];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    
	if (section == 0) {
		UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, 226, 40)];
		headerLabel.text = self.headerText;
		headerLabel.font = [UIFont boldSystemFontOfSize:16];
		headerLabel.textColor = [UIColor darkGrayColor];
		headerLabel.numberOfLines = 0;
		headerLabel.backgroundColor = [UIColor clearColor];
		[headerView addSubview:headerLabel];
		if (_leafLevel) {
			headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
			headerLabel.frame = CGRectMake(headerLabel.frame.origin.x, headerLabel.frame.origin.y, 200, headerLabel.frame.size.height);
			UIButton* viewAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
			UIImage* viewAllImage = [UIImage imageNamed:@"map/map_viewall.png"];
			viewAllButton.frame = CGRectMake(320-viewAllImage.size.width-10, 10, viewAllImage.size.width, viewAllImage.size.height);
			[viewAllButton setImage:viewAllImage forState:UIControlStateNormal];
			[viewAllButton setImage:[UIImage imageNamed:@"map/map_viewall_pressed.png"] forState:UIControlStateHighlighted];
			[viewAllButton addTarget:self action:@selector(mapAllButtonTapped) forControlEvents:UIControlEventTouchUpInside];
			[headerView addSubview:viewAllButton];
		}
	}
	return headerView;
}


#pragma mark MapAll
-(void) mapAllButtonTapped
{
	// make sure the map is showing. 
	[self.mapSelectionController.mapVC showListView:NO];
	
	// clear the search bar
	self.mapSelectionController.mapVC.searchBar.text = @"";
	self.mapSelectionController.mapVC.lastSearchText = nil;
	
	NSMutableArray* searchResultsArray = [NSMutableArray array];
	
	for (NSDictionary* thisItem in self.itemsInTable) {
		MITMapSearchResultAnnotation* annotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:thisItem];
		[searchResultsArray addObject:annotation];
	}
	
	// this will remove any old annotations and add the new ones. 
	[self.mapSelectionController.mapVC setSearchResults:searchResultsArray];
		
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark JSONLoadedDelegate
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{
	NSArray *categoryResults = JSONObject;
	
	self.itemsInTable = [NSMutableArray arrayWithArray:categoryResults];
	
	if (self.loadingView) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		[self.loadingView removeFromSuperview];
		
		if(self.leafLevel) {
			self.tableView.backgroundColor = [UIColor whiteColor];
		}
	}
	
	[self.tableView reloadData];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	if (self.loadingView) {
		[self.loadingView removeFromSuperview];
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Map";
}

-(void) executeServerCategoryRequestWithQuery:(NSString *)query 
{
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"map"
                                                                            command:@"category"
                                                                         parameters:@{@"id":query}];
    operation.userData = @"Category";
    operation.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mime, NSError *error) {
        [self operation:operation
   didFinishWithContent:content
               mimeType:mime
                  error:error];
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:operation];
}

- (void)operation:(MobileRequestOperation*)operation didFinishWithContent:(id)content
         mimeType:(NSString*)mime
            error:(NSError*)error {
    if ([content isKindOfClass:[NSArray class]]) {
        NSArray *categoryResults = (NSArray*)content;
        
        self.itemsInTable = [NSMutableArray arrayWithArray:categoryResults];
        
        if (self.loadingView) {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            [self.loadingView removeFromSuperview];
            
            if(self.leafLevel) {
                self.tableView.backgroundColor = [UIColor whiteColor];
            }
        }
        
        [self.tableView reloadData];
    } else {
        if (self.loadingView) {
            [self.loadingView removeFromSuperview];
        }
        
        [[UIAlertView alertViewForError:error
                              withTitle:@"Map"
                      alertViewDelegate:nil] show];
    }
}

@end
