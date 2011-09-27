#import "WorldCatSearchController.h"
#import "WorldCatBook.h"
#import "LibrariesModule.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"

#define ACTIVITY_ORIGIN_X 20
#define ACTIVITY_ORIGIN_Y 20
#define ACTIVITY_SIZE 30
#define ACTIVITY_TAG 1
#define LABEL_ORIGIN_X 70
#define LABEL_ORIGIN_Y 20
#define LABEL_TAG 2
#define LOADER_HEIGHT 70

@interface WorldCatSearchController (Private)

- (void)doSearch;
- (void)showSearchError;

- (void)initLoadMoreViewToTableView:(UITableView *)tableView;
- (void)updateLoaderView;

@end

@implementation WorldCatSearchController
@synthesize nextIndex;
@synthesize searchTerms;
@synthesize searchResults;
@synthesize searchResultsTableView;
@synthesize loadMoreView;
@synthesize lastSearchAttempt;

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
        self.lastSearchAttempt = [[NSDate date] timeIntervalSince1970];
        if (error) {
            NSLog(@"Request failed with error: %@",[error localizedDescription]);
            [self showSearchError];
            self.searchingStatus = BooksSearchingStatusFailed;
            [self.searchResultsTableView reloadData];
        } else {
            id aNextIndex = [jsonResult objectForKey:@"nextIndex"];
            if (aNextIndex) {
                if([aNextIndex isKindOfClass:[NSNumber class]]) {
                    self.nextIndex = aNextIndex;
                } else {
                    NSLog(@"World cat next index field invaild");
                    self.searchingStatus = BooksSearchingStatusFailed;
                    [self.searchResultsTableView reloadData];
                    [self showSearchError];
                    return;
                }
            } else {
                self.nextIndex = nil;
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
                NSLog(@"World cat result not an array");
                self.searchingStatus = BooksSearchingStatusFailed;
                [self.searchResultsTableView reloadData];
                [self showSearchError];
            }            
        }
    };
    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.searchResults) {
        if (self.nextIndex) {
            return [NSString stringWithFormat:@"Showing the first %@ results", self.nextIndex];
        } else {
            return [NSString stringWithFormat:@"%d results found", self.searchResults.count];
        }
    }
    return nil;
}

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
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        [cell applyStandardFonts];
    }
    WorldCatBook *book = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = book.title;
    cell.detailTextLabel.text = [book.authors componentsJoinedByString:@" "];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.searchResults.count) {
        [self doSearch];
    }
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

- (void)initLoadMoreViewToTableView:(UITableView *)tableView {
    if (!self.loadMoreView) {
        self.loadMoreView = [[[UIView alloc] initWithFrame:CGRectMake(
                                                                      0, tableView.contentSize.height, tableView.frame.size.width, LOADER_HEIGHT)] autorelease];
        UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] 
                                                  initWithFrame:CGRectMake(ACTIVITY_ORIGIN_X, ACTIVITY_ORIGIN_Y, ACTIVITY_SIZE, ACTIVITY_SIZE)] autorelease];
        activityView.tag = ACTIVITY_TAG;
        [self.loadMoreView addSubview:activityView];
        
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(LABEL_ORIGIN_X, LABEL_ORIGIN_Y, 200.0, 30)] autorelease];
        label.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
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
            label.text = @"Loading...";
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
    self.searchingStatus = BooksSearchingStatusNotLoaded;
}

@end
