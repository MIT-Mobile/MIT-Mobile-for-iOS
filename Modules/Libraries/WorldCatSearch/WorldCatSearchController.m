#import "WorldCatSearchController.h"
#import "WorldCatBook.h"
#import "LibrariesModule.h"
#import "LibrariesBookDetailViewController.h"
#import "MobileRequestOperation.h"
#import "MITLoadingActivityView.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"

#define ACTIVITY_ORIGIN_X 8
#define ACTIVITY_ORIGIN_Y 20
#define ACTIVITY_SIZE 30
#define LABEL_ORIGIN_X 40
#define LABEL_ORIGIN_Y 20

#define LOADER_HEIGHT 70

typedef enum {
    ACTIVITY_TAG = 1,
    LABEL_TAG,
    LOADING_ACTIVITY_TAG,
    CELL_CUSTOM_LABEL_TAG, 
    CELL_CUSTOM_DETAIL_LABEL_TAG 
} WorldCatSearchViewTags;

@interface WorldCatSearchController (Private)

- (void)doSearch;
- (void)showSearchError;

- (void)initLoadMoreViewToTableView:(UITableView *)tableView;
- (void)updateLoaderView;
- (NSNumber *)getNumberFromDict:(NSDictionary *)dict forKey:(NSString *)key required:(BOOL)required;
+ (UIEdgeInsets)searchCellMargins;

@end

@implementation WorldCatSearchController
@synthesize totalResultsCount;
@synthesize nextIndex;
@synthesize searchTerms;
@synthesize searchResults;
@synthesize searchResultsTableView;
@synthesize loadMoreView;
@synthesize lastSearchAttempt;
@synthesize navigationController;
@synthesize parseError;

- (id) init {
    self = [super init];
    if (self) {
        self.searchingStatus = BooksSearchingStatusLoaded;
    }
    return self;
}

- (void)dealloc {
    self.searchTerms = nil;
    self.searchResults = nil;
    self.nextIndex = nil;
    self.totalResultsCount = nil;
    self.searchResultsTableView = nil;
    self.loadMoreView = nil;
    [super dealloc];
}

- (void) doSearch:(NSString *)theSearchTerms {
    self.searchResults = nil;
    self.nextIndex = nil;
    self.searchTerms = theSearchTerms;
    [self doSearch];
}

- (void) doSearch {
    
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:searchTerms forKey:@"q"];
    if (self.nextIndex) {
        [parameters setObject:[NSString stringWithFormat:@"%d", [self.nextIndex intValue]] forKey:@"startIndex"];
    }
    
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:LibrariesTag command:@"search" parameters:parameters] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        UIView *loadingView = [self.searchResultsTableView viewWithTag:LOADING_ACTIVITY_TAG];
        [loadingView removeFromSuperview];
        
        self.lastSearchAttempt = [[NSDate date] timeIntervalSince1970];
        if (error) {
            DLog(@"Request failed with error: %@",[error localizedDescription]);
            [self showSearchError];
            self.searchingStatus = BooksSearchingStatusFailed;
            [self.searchResultsTableView reloadData];
        } else {
            self.nextIndex = [self getNumberFromDict:jsonResult forKey:@"nextIndex" required:NO];
            self.totalResultsCount = [self getNumberFromDict:jsonResult forKey:@"totalResultsCount" required:YES];
            if (self.parseError) {
                WLog(@"World cat parse error parsing nextIndex or totalResultsCount");
                self.searchingStatus = BooksSearchingStatusFailed;
                [self.searchResultsTableView reloadData];
                [self showSearchError];
                return;
            }
            
            id items = [jsonResult objectForKey:@"items"];
            if ([items isKindOfClass:[NSArray class]]) {
                NSMutableArray *temporarySearchResults = [NSMutableArray array];
                for (NSDictionary *dict in items) {
                    WorldCatBook *book = [[[WorldCatBook alloc] initWithDictionary:dict] autorelease];
                    if (book.parseFailure) {
                        self.searchingStatus = BooksSearchingStatusFailed;
                        [self.searchResultsTableView reloadData];
                        [self showSearchError];
                        return;
                    }
                    [temporarySearchResults addObject:book];
                }
                self.searchingStatus = BooksSearchingStatusLoaded;
                if (!self.searchResults) {
                    self.searchResults = [NSMutableArray array];
                }
                [self.searchResults addObjectsFromArray:temporarySearchResults];                
                [self.searchResultsTableView reloadData];
            } else {
                WLog(@"World cat result not an array");
                self.searchingStatus = BooksSearchingStatusFailed;
                [self.searchResultsTableView reloadData];
                [self showSearchError];
            }            
        }
    };
    
    // show loading indicator for initial search
    if (!self.nextIndex) {
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.searchResultsTableView.bounds] autorelease];
        loadingView.tag = LOADING_ACTIVITY_TAG;
        [self.searchResultsTableView addSubview:loadingView];
    }
    
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:request];
    self.searchingStatus = BooksSearchingStatusLoading;
}

- (void)showSearchError {
    // only show errors for fresh searches not for a load more search
    if (!self.nextIndex) {
        [MITMobileWebAPI showErrorWithHeader:@"WorldCat Search"];
    }
}

- (void)initLoadMoreViewToTableView:(UITableView *)tableView {
    if (!self.loadMoreView) {
        self.loadMoreView = [[[UIView alloc] initWithFrame:CGRectMake(
                                                                      0, tableView.contentSize.height, tableView.frame.size.width, LOADER_HEIGHT)] autorelease];
        UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] 
                                                  initWithFrame:CGRectMake(ACTIVITY_ORIGIN_X, ACTIVITY_ORIGIN_Y, ACTIVITY_SIZE, ACTIVITY_SIZE)] autorelease];
        activityView.tag = ACTIVITY_TAG;
        [self.loadMoreView addSubview:activityView];
        
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(LABEL_ORIGIN_X, LABEL_ORIGIN_Y, 200.0, 30)] autorelease];
        label.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        label.textColor = CELL_STANDARD_FONT_COLOR;
        label.tag = LABEL_TAG;
        [self.loadMoreView addSubview:label];        
        self.loadMoreView.backgroundColor = [UIColor clearColor];
    }
    if (self.nextIndex) {
        if (self.loadMoreView.superview != tableView) {
            [self.loadMoreView removeFromSuperview];
            [tableView addSubview:self.loadMoreView];
        }
        if (self.loadMoreView.frame.origin.y != tableView.contentSize.height) {
            CGRect loadMoreFrame = self.loadMoreView.frame;
            loadMoreFrame.origin.y = tableView.contentSize.height;
            self.loadMoreView.frame = loadMoreFrame;
        }
        if (tableView.contentInset.bottom != LOADER_HEIGHT) {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, LOADER_HEIGHT, 0);
        }
    } else {
        [self.loadMoreView removeFromSuperview];
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.nextIndex && self.searchingStatus != BooksSearchingStatusLoading) {
        if (self.searchingStatus == BooksSearchingStatusFailed) {
            // if the last search failed wait some minimum amount of time
            // for the next attempt
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            if (currentTime - self.lastSearchAttempt < 20) {
                // skip search attempt
                return;
            }
        }
        if (scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - scrollView.frame.size.height) {
            [self doSearch];
        }
    }
}

- (BooksSearchingStatus)searchingStatus {
    return _searchingStatus;
}

- (void)setSearchingStatus:(BooksSearchingStatus)searchingStatus {
    _searchingStatus = searchingStatus;
    [self updateLoaderView];
}

- (void)updateLoaderView {
    if (self.loadMoreView) {
        UIActivityIndicatorView *activityView = (UIActivityIndicatorView *)[self.loadMoreView viewWithTag:ACTIVITY_TAG];
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        UILabel *label = (UILabel *)[self.loadMoreView viewWithTag:LABEL_TAG];
        if (self.searchingStatus == BooksSearchingStatusLoading) {
            activityView.hidden = NO;
            [activityView startAnimating];
            label.text = @"Loading…";
        } else {
            activityView.hidden = YES;
            [activityView stopAnimating];
        }
        
        if (self.searchingStatus == BooksSearchingStatusFailed) {
            label.text = @"Loading more failed";
        }
    }
}

- (void)clearSearch {
    self.searchResults = nil;
    self.searchResultsTableView = nil;
    self.nextIndex = nil;
    self.parseError = NO;
    self.totalResultsCount = nil;
    self.searchingStatus = BooksSearchingStatusNotLoaded;
}

- (NSNumber *)getNumberFromDict:(NSDictionary *)dict forKey:(NSString *)key required:(BOOL)required {
    NSNumber *number = (NSNumber *)[dict objectForKey:key];
    if (!number) {
        if (required) {
            self.parseError = YES;
        }
    } else {
        if (![number isKindOfClass:[NSNumber class]]) {
            self.parseError = YES;
            return nil;
        }
    }
    return number;
}

+(UIEdgeInsets)searchCellMargins {
    return UIEdgeInsetsMake(13.0, 10.0, 13.0, 30.0);
}

#pragma mark UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self initLoadMoreViewToTableView:tableView];
    self.searchResultsTableView = tableView;
    
    if (!self.searchResults) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"] autorelease];            
        }        
        return cell;
    }
    
    NSString *cellIdentifier = @"book";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) 
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
        cell.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    WorldCatBook *book = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = book.title;
    cell.detailTextLabel.text = [book yearWithAuthors];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchResults) {
        WorldCatBook *book = [self.searchResults objectAtIndex:indexPath.row];
        UIEdgeInsets margins = [[self class] searchCellMargins];
        CGFloat availableWidth = CGRectGetWidth(tableView.bounds) - (margins.left + margins.right);
        
        CGSize titleSize = [book.title sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(availableWidth, 2000.0) lineBreakMode:UILineBreakModeWordWrap];
        
        CGSize detailSize = [[book yearWithAuthors] sizeWithFont:[UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE] forWidth:availableWidth lineBreakMode:UILineBreakModeTailTruncation];
        
        return titleSize.height + detailSize.height + margins.top + margins.bottom;
    } else {
        return tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchResults) {
        return UNGROUPED_SECTION_HEADER_HEIGHT;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.searchResults) {
        NSString *title;
        title = [NSString stringWithFormat:@"%d results", [self.totalResultsCount intValue]];
        return [UITableView ungroupedSectionHeaderWithTitle:title];    
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WorldCatBook *book = [self.searchResults objectAtIndex:indexPath.row];
    LibrariesBookDetailViewController *vc = [[LibrariesBookDetailViewController new] autorelease];
    vc.book = book;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchResults) {
        return self.searchResults.count;
    }
    return 1;  // returning 1 prevents "No results"
}


@end
