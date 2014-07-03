#import "MITNewsiPadViewController.h"
#import "MITNewsPadLayout.h"
#import "MITNewsModelController.h"
#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsConstants.h"

#import "MITNewsListViewController.h"
#import "MITNewsGridViewController.h"
#import "MITMobile.h"
#import "MITCoreData.h"

#import "MITNewsStoriesDataSource.h"

@interface MITNewsiPadViewController (NewsDataSource) <MITNewsStoryDataSource,MITNewsStoryDelegate>
@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSOrderedSet *searchResults;

- (BOOL)canLoadMoreItems;
- (void)loadMoreItems:(void(^)(NSError *error))block;
- (void)reloadItems:(void(^)(NSError *error))block;

- (void)reloadDataSources;
@end

@interface MITNewsiPadViewController ()
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet MITNewsGridViewController *gridViewController;
@property (nonatomic, weak) IBOutlet MITNewsListViewController *listViewController;

@property (nonatomic, readonly, weak) UIViewController *activeViewController;
@property (nonatomic, getter=isSearching) BOOL searching;

#pragma mark Data Source
@property (nonatomic,copy) NSArray *categories;
@property (nonatomic,copy) NSArray *dataSources;
@end

@implementation MITNewsiPadViewController {
    BOOL _isTransitioningToPresentationStyle;
}

@synthesize activeViewController = _activeViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.gridViewController.collectionView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;
    self.showsFeaturedStories = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        [self setPresentationStyle:MITNewsPresentationStyleGrid animated:animated];
    } else {
        [self setPresentationStyle:MITNewsPresentationStyleList animated:animated];
    }

    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [self reloadItems:^(NSError *error) {
        if (error) {
            DDLogWarn(@"update failed; %@",error);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Dynamic Properties
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    }

    return _managedObjectContext;
}

- (MITNewsGridViewController*)gridViewController
{
    if (![self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
        return nil;
    } else if (!_gridViewController) {
        MITNewsGridViewController *gridViewController = [[MITNewsGridViewController alloc] init];
        gridViewController.delegate = self;
        gridViewController.dataSource = self;
        
        [self addChildViewController:gridViewController];
        _gridViewController = gridViewController;
    }

    return _gridViewController;
}

- (MITNewsListViewController*)listViewController
{
    if (![self supportsPresentationStyle:MITNewsPresentationStyleList]) {
        return nil;
    } else if (!_listViewController) {
        MITNewsListViewController *listViewController = [[MITNewsListViewController alloc] init];
        listViewController.delegate = self;
        listViewController.dataSource = self;

        [self addChildViewController:listViewController];
        _listViewController = listViewController;
    }
    
    return _listViewController;
}

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
            [UIView transitionWithView:self.containerView
                              duration:animationDuration
                               options:0
                            animations:^{
                                [self.containerView addSubview:toViewController.view];
                            } completion:^(BOOL finished) {
                                _isTransitioningToPresentationStyle = NO;
                            }];
        } else {
            [self transitionFromViewController:fromViewController
                              toViewController:toViewController
                                      duration:animationDuration
                                       options:0
                                    animations:nil
                                    completion:^(BOOL finished) {
                                        _isTransitioningToPresentationStyle = NO;
                                    }];
        }
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

#pragma mark UI Actions
- (IBAction)searchButtonWasTriggered:(UIBarButtonItem *)sender
{
    
}

- (IBAction)showStoriesAsGrid:(UIBarButtonItem *)sender
{
    self.presentationStyle = MITNewsPresentationStyleGrid;
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    self.presentationStyle = MITNewsPresentationStyleList;
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];

    if (self.presentationStyle == MITNewsPresentationStyleList) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleGrid]) {
            UIBarButtonItem *gridItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(showStoriesAsGrid:)];
            [rightBarItems addObject:gridItem];
        }
    } else if (self.presentationStyle == MITNewsPresentationStyleGrid) {
        if ([self supportsPresentationStyle:MITNewsPresentationStyleList]) {
            UIImage *listImage = [UIImage imageNamed:@"map/item_list"];
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesAsList:)];
            [rightBarItems addObject:listItem];
        }
    }
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonWasTriggered:)];
    [rightBarItems addObject:searchItem];
    
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
}

@end

@implementation MITNewsiPadViewController (NewsDataSource)
- (void)reloadDataSources
{
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];

    if (self.showsFeaturedStories) {
        MITNewsDataSource *featuredDataSource = [MITNewsStoriesDataSource featuredStoriesDataSource];
        featuredDataSource.maximumNumberOfItemsPerPage = 5;
        [dataSources addObject:featuredDataSource];
    }

    __weak MITNewsiPadViewController *weakSelf = self;
    [[MITNewsModelController sharedController] categories:^(NSArray *categories, NSError *error) {
        MITNewsiPadViewController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else {
            NSMutableOrderedSet *categorySet = [[NSMutableOrderedSet alloc] init];

            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                NSManagedObjectID *objectID = [category objectID];
                NSError *error = nil;
                NSManagedObject *object = [blockSelf.managedObjectContext existingObjectWithID:objectID error:&error];

                if (!object) {
                    DDLogWarn(@"failed to retreive object for ID %@: %@",object,error);
                } else {
                    [categorySet addObject:object];
                }
            }];

            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                MITNewsDataSource *dataSource = [MITNewsStoriesDataSource dataSourceForCategory:category];
                [dataSources addObject:dataSource];
            }];

            blockSelf.categories = [categorySet array];
            blockSelf.dataSources = dataSources;
            [blockSelf refreshDataSources];
        }
    }];
}

- (void)refreshDataSources
{
    __block dispatch_group_t refreshGroup = dispatch_group_create();

    [self.dataSources enumerateObjectsUsingBlock:^(MITNewsDataSource *dataSource, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(refreshGroup);

        [dataSource refresh:^(NSError *error) {
            if (error) {
                DDLogWarn(@"failed to refresh data source %@",dataSource);
            } else {
                DDLogVerbose(@"refreshed data source %@",dataSource);
            }

            dispatch_group_leave(refreshGroup);
        }];
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_group_wait(refreshGroup, DISPATCH_TIME_FOREVER);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.activeViewController == self.gridViewController) {
                [self.gridViewController.collectionView reloadData];
            } else if (self.activeViewController == self.listViewController) {
                [self.listViewController.tableView reloadData];
            }
        }];
    });
}

- (MITNewsDataSource*)dataSourceForCategoryInSection:(NSUInteger)section
{
    return self.dataSources[section];
}

- (BOOL)canLoadMoreItemsForCategoryInSection:(NSUInteger)section
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:index];
    return [dataSource hasNextPage];
}

- (BOOL)loadMoreItemsForCategoryInSection:(NSUInteger)section completion:(void(^)(NSError *error))block
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:index];
    return [dataSource nextPage:block];
}

- (void)reloadItems:(void(^)(NSError *error))block
{
    [self reloadDataSources];
}

- (BOOL)viewController:(UIViewController*)viewController isFeaturedCategoryInSection:(NSUInteger)section
{
    if (self.isSearching) {
        return NO;
    } else if (self.showsFeaturedStories && (index == 0)) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController
{
    return [self.dataSources count];
}

- (NSString*)viewController:(UIViewController*)viewController titleForCategoryInSection:(NSUInteger)section
{
    if (self.isSearching) {
        return nil;
    } else if (self.showsFeaturedStories && (section == 0)) {
        return @"Featured";
    } else {
        __block NSString *title = nil;
        --section;

        MITNewsCategory *category = self.categories[section];
        [category.managedObjectContext performBlockAndWait:^{
            title = category.identifier;
        }];

        return title;
    }
}

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    if (self.showsFeaturedStories && (section == 0)) {
        return 5;
    } else {
        MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
        return MIN([dataSource.objects count],10);
    }
}

- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section
{
    MITNewsDataSource *dataSource = [self dataSourceForCategoryInSection:section];
    return dataSource.objects[index];
}

@end