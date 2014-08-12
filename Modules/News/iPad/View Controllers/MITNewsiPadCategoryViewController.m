#import "MITNewsiPadCategoryViewController.h"
#import "MITNewsCategoryListViewController.h"
#import "MITNewsCategoryGridViewController.h"
#import "MITNewsSearchController.h"
#import "MITCoreData.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesDataSource.h"
#import "MITNewsConstants.h"

@interface MITNewsiPadCategoryViewController (NewsDataSource) <MITNewsStoryDataSource>

@end

@interface MITNewsiPadCategoryViewController (NewsDelegate) <MITNewsStoryDelegate, MITNewsSearchDelegate, MITNewsStoryViewControllerDelegate>

@end

@interface MITNewsiPadCategoryViewController ()
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet MITNewsCategoryGridViewController *gridViewController;
@property (nonatomic, weak) IBOutlet MITNewsCategoryListViewController *listViewController;
@property (nonatomic, strong) MITNewsSearchController *searchController;

@property (nonatomic, readonly, weak) UIViewController *activeViewController;
@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *searchBarWrapper;

@end

@implementation MITNewsiPadCategoryViewController {
    BOOL _isTransitioningToPresentationStyle;
}

@synthesize presentationStyle = _presentationStyle;
@synthesize activeViewController = _activeViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.activeViewController) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid] && self.previousPresentationStyle == MITNewsPresentationStyleGrid) {
            [self setPresentationStyle:MITNewsPresentationStyleGrid animated:animated];
        } else {
            [self setPresentationStyle:MITNewsPresentationStyleList animated:animated];
        }
    }
    [self updateNavigationItem:YES];
}

- (MITNewsCategoryGridViewController*)gridViewController
{
    MITNewsCategoryGridViewController *gridViewController = _gridViewController;
    
    if (![self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        return nil;
    } else if (!gridViewController) {
        gridViewController = [[MITNewsCategoryGridViewController alloc] init];
        gridViewController.delegate = self;
        gridViewController.dataSource = self;
        _gridViewController = gridViewController;
    }
    
    return gridViewController;
}

- (MITNewsCategoryListViewController*)listViewController
{
    MITNewsCategoryListViewController *listViewController = _listViewController;
    
    if (![self supportsPresentationStyle:MITNewsPresentationStyleList]) {
        return nil;
    } else if (!listViewController) {
        listViewController = [[MITNewsCategoryListViewController alloc] init];
        listViewController.delegate = self;
        listViewController.dataSource = self;
        _listViewController = listViewController;
    }
    
    return listViewController;
}

- (MITNewsSearchController *)searchController
{
    if(!_searchController) {
        MITNewsSearchController *searchController = [[MITNewsSearchController alloc] init];
        searchController.view.frame = self.containerView.bounds;
        searchController.delegate = self;
        _searchController = searchController;
    }
    
    return _searchController;
}

- (UISearchBar *)searchBar
{
    if(!_searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self.searchController;
        self.searchController.searchBar = searchBar;
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.showsCancelButton = YES;
        _searchBar = searchBar;
    }
    return _searchBar;
}

#pragma mark UI Actions
- (void)setPresentationStyle:(MITNewsPresentationStyle)style
{
    [self setPresentationStyle:style animated:NO];
}

- (void)setPresentationStyle:(MITNewsPresentationStyle)style animated:(BOOL)animated
{
    NSAssert([self supportsPresentationStyle:style], @"presentation style %d is not supported on this device", style);
    
    if (![self supportsPresentationStyle:style]) {
        return;
    } else if ((_presentationStyle != style) || !self.activeViewController) {
        _presentationStyle = style;
        
        // Figure out which view controllers we are going to be
        // transitioning from/to.
        UIViewController *fromViewController = self.activeViewController;
        UIViewController *toViewController = nil;
        if (_presentationStyle == MITNewsPresentationStyleGrid) {
            toViewController = self.gridViewController;
        } else {
            toViewController = self.listViewController;
        }
        
        const CGRect viewFrame = self.containerView.bounds;
        fromViewController.view.frame = viewFrame;
        toViewController.view.frame = viewFrame;
        
        const NSTimeInterval animationDuration = (animated ? 0.25 : 0);
        _isTransitioningToPresentationStyle = YES;
        _activeViewController = toViewController;
        if (!fromViewController) {
            [self addChildViewController:toViewController];
            
            [UIView transitionWithView:self.containerView
                              duration:animationDuration
                               options:0
                            animations:^{
                                [self.containerView addSubview:toViewController.view];
                            } completion:^(BOOL finished) {
                                _isTransitioningToPresentationStyle = NO;
                                [toViewController didMoveToParentViewController:self];
                            }];
        } else {
            [fromViewController willMoveToParentViewController:nil];
            [self addChildViewController:toViewController];
            
            [self transitionFromViewController:fromViewController
                              toViewController:toViewController
                                      duration:animationDuration
                                       options:0
                                    animations:nil
                                    completion:^(BOOL finished) {
                                        _isTransitioningToPresentationStyle = NO;
                                        [toViewController didMoveToParentViewController:self];
                                        [fromViewController removeFromParentViewController];
                                    }];
        }
    }
}


- (IBAction)searchButtonWasTriggered:(UIBarButtonItem *)sender
{
    self.searching = YES;
    [self updateNavigationItem:YES];
    [self addChildViewController:self.searchController];
    [self.containerView addSubview:self.searchController.view];
    [self.searchController didMoveToParentViewController:self];
    [UIView animateWithDuration:(0.33)
                          delay:0.
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         self.searchController.view.alpha = .5;
                     } completion:^(BOOL finished) {
                     }];
    [self.searchBar becomeFirstResponder];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSURL *url = [NSURL URLWithString:alertView.message];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    if (_presentationStyle == MITNewsPresentationStyleList) {
        [self.listViewController.tableView deselectRowAtIndexPath:[self.listViewController.tableView indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark Utility Methods
- (BOOL)supportsPresentationStyle:(MITNewsPresentationStyle)style
{
    if (style == MITNewsPresentationStyleList) {
        return YES;
    } else if (style == MITNewsPresentationStyleGrid) {
        const CGFloat minimumWidthForGrid = 768.;
        const CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
        
        return (boundsWidth >= minimumWidthForGrid);
    }
    return NO;
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];
    
    if (self.presentationStyle == MITNewsPresentationStyleList) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
            UIImage *gridImage = [UIImage imageNamed:@"news/gridViewIcon"];
            UIBarButtonItem *gridItem = [[UIBarButtonItem alloc] initWithImage:gridImage style:UIBarButtonSystemItemStop target:self action:@selector(showStoriesAsGrid:)];
            if (self.searching) {
                gridItem.enabled = NO;
                self.navigationItem.hidesBackButton = YES;
            } else {
                self.navigationItem.hidesBackButton = NO;
            }
            [rightBarItems addObject:gridItem];
        }
    } else if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleList]) {
            UIImage *listImage = [UIImage imageNamed:@"map/item_list"];
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesAsList:)];
            if (self.searching) {
                listItem.enabled = NO;
                self.navigationItem.hidesBackButton = YES;
            } else {
                self.navigationItem.hidesBackButton = NO;
            }
            [rightBarItems addObject:listItem];
        }
    }
    if (self.searching) {
        UISearchBar *searchBar = self.searchBar;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.searchBar.frame = CGRectMake(0, 0, 400, 44);
        } else {
            self.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width - 50, 44);
        }
        
        self.searchBarWrapper = [[UIView alloc]initWithFrame:searchBar.bounds];
        [self.searchBarWrapper addSubview:searchBar];
        UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBarWrapper];
        [rightBarItems addObject:searchBarItem];
        [self.navigationItem setTitle:@""];
        self.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    } else {
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonWasTriggered:)];
        [rightBarItems addObject:searchItem];
        [self.navigationItem setTitle:self.categoryTitle];
        self.navigationController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    }
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
}

@end

@implementation MITNewsiPadCategoryViewController (NewsDataSource)
- (MITNewsDataSource*)dataSourceForCategoryInSection:(NSUInteger)section
{
    return self.dataSource;
}

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController
{
    return ([self.dataSource.objects count] ? 1 : 0);
}

- (NSString*)viewController:(UIViewController*)viewController titleForCategoryInSection:(NSUInteger)section
{
    return nil;
}

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    return [self.dataSource.objects count];
}

- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    if ([dataSource.objects count ] > index) {
        return dataSource.objects[index];
    } else {
        return nil;
    }
}

@end

@implementation MITNewsiPadCategoryViewController (NewsDelegate)

#pragma mark MITNewsStoryDetailPagingDelegate

- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryInSection:(NSUInteger)index;
{
    return nil;
}

- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section;
{
    MITNewsStory *story = [self viewController:self storyAtIndex:index forCategoryInSection:section];
    if (story) {
        __block BOOL isExternalStory = NO;
        __block NSURL *externalURL = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if ([story.type isEqualToString:MITNewsStoryExternalType]) {
                isExternalStory = YES;
                externalURL = story.sourceURL;
            }
        }];
        
        if (isExternalStory) {
            NSString *message = [NSString stringWithFormat:@"Open in Safari?"];
            UIAlertView *willOpenInExternalBrowserAlertView = [[UIAlertView alloc] initWithTitle:message message:[externalURL absoluteString] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
            [willOpenInExternalBrowserAlertView show];
        } else {
            [self performSegueWithIdentifier:@"showStoryDetail" sender:[NSIndexPath indexPathForItem:index inSection:section]];
        }
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {
            
            NSIndexPath *indexPath = sender;
            
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
            storyDetailViewController.delegate = self;
            MITNewsStory *story = [self viewController:self storyAtIndex:indexPath.row forCategoryInSection:indexPath.section];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
                
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}


#pragma mark MITNewsStoryDetailPagingDelegate

- (void)storyAfterStory:(MITNewsStory *)story completion:(void (^)(MITNewsStory *, NSError *))block
{
    
    MITNewsStory *currentStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
    
    MITNewsDataSource *dataSource = self.dataSource;
    
    NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
    if (currentIndex != NSNotFound) {
        
        if (currentIndex + 1 < [dataSource.objects count]) {
            if(block) {
                block(dataSource.objects[currentIndex + 1], nil);
            }
        } else {
            if ([dataSource hasNextPage]) {
                [dataSource nextPage:^(NSError *error) {
                    if (error) {
                        DDLogWarn(@"failed to refresh data source %@",dataSource);
                    } else {
                        DDLogVerbose(@"refreshed data source %@",dataSource);
                        NSInteger currentIndex = [dataSource.objects indexOfObject:currentStory];
                        
                        if (currentIndex + 1 < [dataSource.objects count]) {
                            if(block) {
                                block(dataSource.objects[currentIndex + 1], nil);
                            }
                        }
                    }
                }];
            }
        }
    }
}

- (void)hideSearchField
{
    self.searchBar = nil;
    [self.searchController.view removeFromSuperview];
    [self.searchController removeFromParentViewController];
    self.searchController = nil;
    self.searching = NO;
    [self updateNavigationItem:YES];
}
@end
