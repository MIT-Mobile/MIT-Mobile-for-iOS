#import "WorldCatSearchController.h"
#import "WorldCatBook.h"
#import "LibrariesModule.h"
#import "LibrariesBookDetailViewController.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITLoadingActivityView.h"
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

typedef enum {
    BooksSearchingStatusNotLoaded,
    BooksSearchingStatusLoading,
    BooksSearchingStatusLoaded,
    BooksSearchingStatusFailed
} BooksSearchingStatus;


@interface WorldCatSearchController ()
@property (nonatomic,strong) UITableView *searchResultsTableView;
@property (nonatomic,strong) UIView *loadMoreView;

@property (copy) NSString *searchTerms;
@property (strong) NSMutableArray *searchResults;
@property (strong) NSNumber *totalResultsCount;
@property (strong) NSNumber *nextIndex;

@property BOOL parseError;
@property (nonatomic) BooksSearchingStatus searchingStatus;
@property NSTimeInterval lastSearchAttempt;

- (void)doSearch;
- (void)showSearchError;

- (void)initLoadMoreViewToTableView:(UITableView *)tableView;
- (void)updateLoaderView;
- (NSNumber *)getNumberFromDict:(NSDictionary *)dict forKey:(NSString *)key required:(BOOL)required;
+ (UIEdgeInsets)searchCellMargins;

@end

@implementation WorldCatSearchController
- (id) init {
    self = [super init];
    if (self) {
        self.searchingStatus = BooksSearchingStatusLoaded;
    }
    return self;
}

- (void) doSearch:(NSString *)theSearchTerms {
    self.searchResults = nil;
    self.nextIndex = nil;
    self.searchTerms = theSearchTerms;
    [self doSearch];
}

- (void) doSearch {
    LibrariesModule *librariesModule = (LibrariesModule *)[[MIT_MobileAppDelegate applicationDelegate] moduleWithTag:LibrariesTag];
    
    NSDictionary *parameters = nil;
    if (self.nextIndex) {
        parameters = @{@"startIndex" : [NSString stringWithFormat:@"%d",[self.nextIndex intValue]],
                       @"q" : self.searchTerms};
    } else {
        parameters = @{@"q" : self.searchTerms};
    }

    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"search" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak WorldCatSearchController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, id content, NSString *contentType, NSError *error) {
        WorldCatSearchController *blockSelf = weakSelf;

        UIView *loadingView = [self.searchResultsTableView viewWithTag:LOADING_ACTIVITY_TAG];
        [loadingView removeFromSuperview];
        
        self.lastSearchAttempt = [[NSDate date] timeIntervalSince1970];
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogVerbose(@"Request failed with error: %@",[error localizedDescription]);
            [blockSelf showSearchError];
            blockSelf.searchingStatus = BooksSearchingStatusFailed;
            [blockSelf.searchResultsTableView reloadData];
        } else {
            blockSelf.nextIndex = [self getNumberFromDict:content forKey:@"nextIndex" required:NO];
            blockSelf.totalResultsCount = [self getNumberFromDict:content forKey:@"totalResultsCount" required:YES];
            if (self.parseError) {
                DDLogWarn(@"World cat parse error parsing nextIndex or totalResultsCount");
                blockSelf.searchingStatus = BooksSearchingStatusFailed;
                [blockSelf.searchResultsTableView reloadData];
                [blockSelf showSearchError];
                return;
            }
            
            NSArray *items = content[@"items"];
            if ([items isKindOfClass:[NSArray class]]) {
                NSMutableArray *temporarySearchResults = [NSMutableArray array];
                for (NSDictionary *dict in items) {
                    WorldCatBook *book = [[WorldCatBook alloc] initWithDictionary:dict];
                    if (book.parseFailure) {
                        blockSelf.searchingStatus = BooksSearchingStatusFailed;
                        [blockSelf.searchResultsTableView reloadData];
                        [blockSelf showSearchError];
                        return;
                    }

                    [temporarySearchResults addObject:book];
                }

                blockSelf.searchingStatus = BooksSearchingStatusLoaded;
                if (!blockSelf.searchResults) {
                    blockSelf.searchResults = [NSMutableArray array];
                }
                [blockSelf.searchResults addObjectsFromArray:temporarySearchResults];
                [blockSelf.searchResultsTableView reloadData];
            } else {
                DDLogWarn(@"World cat result not an array");
                blockSelf.searchingStatus = BooksSearchingStatusFailed;
                [blockSelf.searchResultsTableView reloadData];
                [blockSelf showSearchError];
            }            
        }
    };
    
    // show loading indicator for initial search
    if (!self.nextIndex) {
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.searchResultsTableView.bounds];
        loadingView.tag = LOADING_ACTIVITY_TAG;
        [self.searchResultsTableView addSubview:loadingView];
    }
    
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:requestOperation];
    self.searchingStatus = BooksSearchingStatusLoading;
}

- (void)showSearchError {
    // only show errors for fresh searches not for a load more search
    if (!self.nextIndex) {
        [UIAlertView alertViewForError:nil withTitle:@"WorldCat Search" alertViewDelegate:nil];
    }
}

- (void)initLoadMoreViewToTableView:(UITableView *)tableView {
    if (!self.loadMoreView) {
        self.loadMoreView = [[UIView alloc] initWithFrame:CGRectMake(0, tableView.contentSize.height, tableView.frame.size.width, LOADER_HEIGHT)];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc]
                                                  initWithFrame:CGRectMake(ACTIVITY_ORIGIN_X, ACTIVITY_ORIGIN_Y, ACTIVITY_SIZE, ACTIVITY_SIZE)];
        activityView.tag = ACTIVITY_TAG;
        [self.loadMoreView addSubview:activityView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_ORIGIN_X, LABEL_ORIGIN_Y, 200.0, 30)];
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
    tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
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
    NSNumber *number = dict[key];
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
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
        }
        
        return cell;
    }
    
    NSString *cellIdentifier = @"book";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    WorldCatBook *book = self.searchResults[indexPath.row];
    cell.textLabel.text = book.title;
    cell.detailTextLabel.text = [book yearWithAuthors];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchResults) {
        WorldCatBook *book = self.searchResults[indexPath.row];
        UIEdgeInsets margins = [[self class] searchCellMargins];
        CGFloat availableWidth = CGRectGetWidth(tableView.bounds) - (margins.left + margins.right);
        
        CGSize titleSize = [book.title sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
                                  constrainedToSize:CGSizeMake(availableWidth, 2000.0)
                                      lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize detailSize = [[book yearWithAuthors] sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]
                                                        forWidth:availableWidth
                                                   lineBreakMode:NSLineBreakByTruncatingTail];
        
        return titleSize.height + detailSize.height + margins.top + margins.bottom;
    } else {
        return tableView.rowHeight;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchResults) {
        return [NSString stringWithFormat:@"%d results", [self.totalResultsCount intValue]];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WorldCatBook *book = self.searchResults[indexPath.row];
    LibrariesBookDetailViewController *vc = [[LibrariesBookDetailViewController alloc] init];
    vc.book = book;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchResults) {
        return [self.searchResults count];
    }
    
    return 1;  // returning 1 prevents "No results"
}


@end
