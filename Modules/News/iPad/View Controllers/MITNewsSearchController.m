#import "MITNewsSearchController.h"
#import "MITNewsModelController.h"
#import "MITNewsRecentSearchController.h"
#import "MITNewsConstants.h"
#import "UITableView+DynamicSizing.h"
#import "MITNewsStory.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStoryViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "DDPopoverBackgroundView.h"

#import "MITNewsStoriesDataSource.h"

@interface MITNewsSearchController (NewsDataSource) <UISearchBarDelegate, UIPopoverControllerDelegate, UITableViewDataSourceDynamicSizing, MITNewsStoryViewControllerDelegate>

@end

@interface MITNewsSearchController()
@property (strong, nonatomic) MITNewsRecentSearchController *recentSearchController;
@property (nonatomic, strong) UIPopoverController *recentSearchPopoverController;
@property (nonatomic) BOOL unwindFromStoryDetail;
@property (nonatomic) MITNewsDataSource *dataSource;

@end

@implementation MITNewsSearchController

@synthesize recentSearchController = _recentSearchController;

#pragma mark - Dynamic Properties

- (MITNewsRecentSearchController *)recentSearchController
{
    if(!_recentSearchController) {
        MITNewsRecentSearchController *recentSearchController = [[MITNewsRecentSearchController alloc] init];
        recentSearchController.searchController = self;
        _recentSearchController = recentSearchController;
    }
    return _recentSearchController;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }
    
    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark - View lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.searchTableView.alpha = 0;

    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [self.searchTableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

#pragma mark - SearchBar

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchField];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self hideSearchRecents];
    self.searchTableView.alpha = 1;

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.recentSearchController addRecentSearchItem:searchBar.text];
    [self getResultsForString:searchBar.text];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (self.unwindFromStoryDetail || self.recentSearchController.confirmSheet != nil) {
        self.unwindFromStoryDetail = NO;
        return NO;
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
#warning Needs better screen size handling
    searchBar.showsCancelButton = YES;
    self.searchTableView.alpha = .5;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self showSearchRecents];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""]) {
        [self clearTable];
    }
    [self.recentSearchController filterResultsUsingString:searchText];
}

- (void)clearTable
{
    self.dataSource = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.searchTableView reloadData];
    }];
}

#pragma mark - search

- (void)getResultsForString:(NSString *)searchTerm
{
    [self clearTable];
    self.searchBar.text = searchTerm;
    __block NSError *updateError = nil;
    self.dataSource = [MITNewsStoriesDataSource dataSourceForQuery:searchTerm];
    [self.dataSource refresh:^(NSError *error) {
        if (error) {
            DDLogWarn(@"failed to refresh data source %@",self.dataSource);
            
            if (!updateError) {
                updateError = error;
            }
        } else {
            DDLogVerbose(@"refreshed data source %@",self.dataSource);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.searchTableView reloadData];
            }];
        }
    }];
    [self.searchBar resignFirstResponder];

    [self.recentSearchPopoverController dismissPopoverAnimated:YES];
    [UIView animateWithDuration:(0.33)
                          delay:0.
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         self.searchTableView.alpha = 1;
                         self.view.alpha = 1;
                     } completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - hide/show Recents

- (void)hideSearchRecents
{
    if (self.recentSearchPopoverController != nil) {
        if (self.recentSearchController.confirmSheet == nil) {

            [self.recentSearchPopoverController dismissPopoverAnimated:YES];
            self.recentSearchPopoverController = nil;
        }
    }
}

- (void)showSearchRecents
{
    if (self.recentSearchPopoverController) {
        return;
    }
    UIPopoverController *recentSearchPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.recentSearchController];
    
    recentSearchPopoverController.popoverContentSize = CGSizeMake(300, 350);
    recentSearchPopoverController.delegate = self;
    recentSearchPopoverController.passthroughViews = @[self.searchBar];
#warning add if dimming effect not wanted.
    recentSearchPopoverController.popoverBackgroundViewClass = [DDPopoverBackgroundView class];
    [[DDPopoverBackgroundView class] setContentInset:0];
    [[DDPopoverBackgroundView class] setTintColor:[UIColor whiteColor]];
    [recentSearchPopoverController presentPopoverFromRect:[self.searchBar bounds] inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    self.recentSearchPopoverController = recentSearchPopoverController;
        
}

- (void)hideSearchField
{
    [self.delegate hideSearchField];
}

#pragma mark - Popover

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    [self.searchBar resignFirstResponder];
    if (self.searchTableView.alpha == 0) {
        [self hideSearchField];
    }
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.recentSearchPopoverController = nil;
}

#pragma mark - TableView


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath forTableView:tableView];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    
    if ([identifier isEqualToString:@"TEST"]) {
        static NSString *CellIdentifier = @"Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [view startAnimating];
        cell.accessoryView = view;
        [self getMoreStories];
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)getMoreStories
{
    __block NSError *updateError = nil;
    if ([self.dataSource hasNextPage]) {
        [self.dataSource nextPage:^(NSError *error) {
            if (error) {
                DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                
                if (!updateError) {
                    updateError = error;
                }
            } else {
                DDLogVerbose(@"refreshed data source %@",self.dataSource);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.searchTableView reloadData];
                }];
            }
        }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.dataSource.objects count]) {
        return [self.dataSource.objects count] + 1;
    }

    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath forTableView:tableView];
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return 44.; // Fixed height for the load more cells
    } else {
        return 100;
#warning correct height not calculated
        return [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath forTableView:(UITableView*)tableView
{
    MITNewsStory *story = nil;
    if ([self.dataSource.objects count] > indexPath.row) {
        story = self.dataSource.objects[indexPath.row];
    }
    if (story) {
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            
            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                if (newsStory.coverImage) {
                    identifier = MITNewsStoryExternalCellIdentifier;
                } else {
                    identifier = MITNewsStoryExternalNoImageCellIdentifier;
                }
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
        
        return identifier;
    } else if ([self.dataSource.objects count]) {
        return @"TEST";
    } else {
        return nil;
    }
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    if ([cell.reuseIdentifier isEqualToString:@"TEST"]) {
       // if (self.searchDisplayController.searchResultsTableView == tableView) {
          //  cell.textLabel.enabled = !_storySearchInProgressToken;
            
           // if (_storySearchInProgressToken) {
                UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [view startAnimating];
                cell.accessoryView = view;
        
        //    } else {
      //          cell.accessoryView = nil;
    //        }
       // }
    } else {
        MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
        
        if (story && [cell isKindOfClass:[MITNewsStoryCell class]]) {
            MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsStory *contextStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
                storyCell.story = contextStory;
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"News_iPad" bundle:nil];
    MITNewsStoryViewController *storyDetailViewController = [storyBoard instantiateViewControllerWithIdentifier:@"NewsStoryView"];
    storyDetailViewController.delegate = self;

    MITNewsStory *story = [self.dataSource.objects objectAtIndex:indexPath.row];
    if (story) {
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.parentContext = self.managedObjectContext;
        storyDetailViewController.managedObjectContext = managedObjectContext;
        storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
    
        self.unwindFromStoryDetail = YES;
        [self.navigationController pushViewController:storyDetailViewController animated:YES];
    }
}

#pragma mark MITNewsStoryDetailPagingDelegate

- (MITNewsStory*)newsDetailController:(MITNewsStoryViewController*)storyDetailController storyAfterStory:(MITNewsStory*)story
{
    
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
    if (currentIndex != NSNotFound) {
        
        if (currentIndex + 1 < [self.dataSource.objects count]) {
            
            return self.dataSource.objects[currentIndex + 1];
        } else {
            __block NSError *updateError = nil;
            if ([self.dataSource hasNextPage]) {
                [self.dataSource nextPage:^(NSError *error) {
                    if (error) {
                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                        
                        if (!updateError) {
                            updateError = error;
                        }
                    } else {
                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                        NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
                        
                        if (currentIndex++ < [self.dataSource.objects count]) {
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.searchTableView reloadData];
                        }];
                    }
                }];
            }
        }
    }
    
    return nil;
}

- (MITNewsStory*)newsDetailController:(MITNewsStoryViewController*)storyDetailController storyBeforeStory:(MITNewsStory*)story
{
    return nil;
}

- (BOOL)newsDetailController:(MITNewsStoryViewController*)storyDetailController canPageToStory:(MITNewsStory*)story
{
    return NO;
}

- (void)newsDetailController:(MITNewsStoryViewController*)storyDetailController didPageToStory:(MITNewsStory*)story
{
    
}

- (void)storyAfterStory:(MITNewsStory *)story return:(void (^)(MITNewsStory *, NSError *))block
{
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
    if (currentIndex != NSNotFound) {
        
        if (currentIndex + 1 < [self.dataSource.objects count]) {
            if(block) {
                block(self.dataSource.objects[currentIndex +1], nil);
            }
        } else {
            __block NSError *updateError = nil;
            if ([self.dataSource hasNextPage]) {
                [self.dataSource nextPage:^(NSError *error) {
                    if (error) {
                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                        
                        if (!updateError) {
                            updateError = error;
                        }
                    } else {
                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                        NSInteger currentIndex = [self.dataSource.objects indexOfObject:currentStory];
                        
                        if (currentIndex + 1 < [self.dataSource.objects count]) {
                            if(block) {
                                block(self.dataSource.objects[currentIndex + 1], nil);
                            }
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.searchTableView reloadData];
                        }];
                    }
                }];
            }
        }
    }
}

@end


