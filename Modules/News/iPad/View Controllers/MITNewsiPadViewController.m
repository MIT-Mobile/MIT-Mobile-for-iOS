#import "MITNewsiPadViewController.h"
#import "MITNewsPadLayout.h"
#import "MITNewsModelController.h"
#import "MITNewsStory.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsConstants.h"
#import "MITNewsStoryDetailController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "MITNewsStoryDetailController.h"

typedef NS_ENUM(NSInteger, MITNewsPadStyle) {
    MITNewsPadStyleInvalid = -1,
    MITNewsPadStyleGrid = 0,
    MITNewsPadStyleList
};

@interface MITNewsiPadViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, MITNewsStoryDetailPagingDelegate>
@property (nonatomic, weak) IBOutlet UICollectionViewController *gridViewController;
@property (nonatomic, weak) IBOutlet UITableViewController *listViewController;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) UIViewController *activeViewController;

@property (nonatomic, strong) NSArray *stories;
@property (nonatomic, strong) MITNewsPadLayout *collectionViewLayout;

- (MITNewsPadStyle)currentStyle;
@end

@implementation MITNewsiPadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    // Do any additional setup after loading the view.
    
    self.collectionViewLayout = [[MITNewsPadLayout alloc] init];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    __weak MITNewsiPadViewController *weakController = self;
    
#warning test data
                            //in_the_media  //_mit_news //around_campus
    [[MITNewsModelController sharedController] storiesInCategory:@"mit_news" query:nil offset:0 limit:20 completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
        MITNewsiPadViewController *strong = weakController;
        if (strong) {
            strong.stories = [[NSArray alloc] initWithArray:stories];
            strong.collectionViewLayout.stories = stories;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [strong.gridViewController.collectionView reloadData];
            }];
        }

    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self showStoriesAsGrid:nil];

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
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }
    
    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

- (UICollectionViewController *)gridViewController
{
    UICollectionViewController *gridViewController = _gridViewController;
    
    if (!gridViewController) {
        
        gridViewController = [[UICollectionViewController alloc] initWithCollectionViewLayout:self.collectionViewLayout];

        gridViewController.collectionView.dataSource = self;
        gridViewController.collectionView.delegate = self;
        gridViewController.collectionView.backgroundView = nil;
        gridViewController.collectionView.backgroundColor = [UIColor whiteColor];
        
        _gridViewController = gridViewController;

    }
    [gridViewController.collectionView registerNib:[UINib nibWithNibName:MITNewsCollectionCellStoryJumboWithCellIdentifier bundle:nil] forCellWithReuseIdentifier:MITNewsCollectionCellStoryJumboWithCellIdentifier];

    [gridViewController.collectionView registerNib:[UINib nibWithNibName:MITNewsCollectionCellStoryDekWithCellIdentifier bundle:nil] forCellWithReuseIdentifier:MITNewsCollectionCellStoryDekWithCellIdentifier];

    [gridViewController.collectionView registerNib:[UINib nibWithNibName:MITNewsCollectionCellStoryClipWithCellIdentifier bundle:nil] forCellWithReuseIdentifier:MITNewsCollectionCellStoryClipWithCellIdentifier];
    
    [gridViewController.collectionView registerNib:[UINib nibWithNibName:MITNewsCollectionCellStoryImageWithCellIdentifier bundle:nil] forCellWithReuseIdentifier:MITNewsCollectionCellStoryImageWithCellIdentifier];

    [gridViewController.collectionView registerNib:[UINib nibWithNibName:MITNewsCollectionReusableHeaderWithCellIdentifier bundle:nil] forSupplementaryViewOfKind:MITNewsCollectionReusableHeaderWithCellIdentifier withReuseIdentifier:MITNewsCollectionReusableHeaderWithCellIdentifier];

    return gridViewController;
}

- (UITableViewController *)listViewController
{
    UITableViewController *listViewController = _listViewController;
    
    if (!listViewController) {
        listViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        listViewController.tableView.dataSource = self;
        listViewController.tableView.delegate = self;
        
        _listViewController = listViewController;
    }
    
    return listViewController;
}

- (MITNewsPadStyle)currentStyle
{
    if ([self.activeViewController isKindOfClass:[UICollectionViewController class]]) {
        return MITNewsPadStyleGrid;
    } else if ([self.activeViewController isKindOfClass:[UITableViewController class]]) {
        return MITNewsPadStyleList;
    } else {
        return MITNewsPadStyleInvalid;
    }
}

#pragma mark UI Actions
- (IBAction)searchButtonWasTriggered:(UIBarButtonItem *)sender
{
    
}

- (IBAction)showStoriesAsGrid:(UIBarButtonItem *)sender
{
    if ([self currentStyle] == MITNewsPadStyleGrid) {
        return;
    } else {
        if (self.activeViewController) {

            [self.activeViewController.view removeFromSuperview];
            [self.activeViewController removeFromParentViewController];
            self.activeViewController = nil;
        }

        UICollectionViewController *collectionView = self.gridViewController;
        [self addChildViewController:collectionView];
        [self.containerView addSubview:collectionView.view];
        collectionView.view.frame = self.containerView.bounds;
        
        self.activeViewController = self.gridViewController;
        
        [self updateNavigationItem:YES];
    }
}

- (IBAction)showStoriesAsList:(UIBarButtonItem *)sender
{
    if ([self currentStyle] == MITNewsPadStyleList) {
        return;
    } else {
        if (self.activeViewController) {
            [self.activeViewController.view removeFromSuperview];
            [self.activeViewController removeFromParentViewController];
            self.activeViewController = nil;
        }
        
        UITableViewController *tableView = self.listViewController;
        [self addChildViewController:tableView];
        [self.containerView addSubview:tableView.view];
        tableView.view.frame = self.containerView.bounds;
        
        self.activeViewController = self.listViewController;
        
        [self updateNavigationItem:YES];
    }
}

- (void)updateNavigationItem:(BOOL)animated
{
    NSMutableArray *rightBarItems = [[NSMutableArray alloc] init];
    
    if ([self currentStyle] == MITNewsPadStyleList) {
        UIBarButtonItem *gridItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(showStoriesAsGrid:)];
        [rightBarItems addObject:gridItem];
    } else if ([self currentStyle] == MITNewsPadStyleGrid) {
        UIImage *listImage = [UIImage imageNamed:@"map/item_list"];
        UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:listImage style:UIBarButtonItemStylePlain target:self action:@selector(showStoriesAsList:)];
        [rightBarItems addObject:listItem];
    }
    
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonWasTriggered:)];
    
    [rightBarItems addObject:searchItem];
    
    [self.navigationItem setRightBarButtonItems:rightBarItems animated:animated];
}


#pragma mark - Delegate Methods
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.stories) {
#warning sample data
        return [@[@"20",@"4",@"3",@"2",@"1"][section] intValue];
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
} 


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = nil;

    MITNewsStory *newsStory = [self.stories objectAtIndex:indexPath.row];
    
    if (newsStory) {
        if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
            identifier = MITNewsCollectionCellStoryClipWithCellIdentifier;
        } else if (newsStory.coverImage)  {
            identifier = MITNewsCollectionCellStoryImageWithCellIdentifier;
        } else {
            identifier = MITNewsCollectionCellStoryDekWithCellIdentifier;
        }
    }
    if (indexPath.row == 0) {
    MITNewsStoryCollectionViewCell *jumboCell = [collectionView
                                      dequeueReusableCellWithReuseIdentifier:MITNewsCollectionCellStoryJumboWithCellIdentifier
                                      forIndexPath:indexPath];

    jumboCell.story = newsStory;
    return jumboCell;
    }
    MITNewsStoryCollectionViewCell *imageCell = [collectionView
                                                 dequeueReusableCellWithReuseIdentifier:identifier
                                                 forIndexPath:indexPath];
    
    imageCell.story = [self.stories objectAtIndex:indexPath.row];
    return imageCell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableView = nil;
    reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                      withReuseIdentifier:MITNewsCollectionReusableHeaderWithCellIdentifier
                                                             forIndexPath:indexPath];
    return reusableView;
}

#pragma mark UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showStoryDetail" sender:indexPath];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"%@",self.stories);
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryDetailController class]]) {
            MITNewsStoryDetailController *storyDetailViewController = (MITNewsStoryDetailController*)destinationViewController;
            storyDetailViewController.delegate = self;
            NSIndexPath *indexPath = sender;
            MITNewsStory *story = [self.stories objectAtIndex:indexPath.row];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];

            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryDetailController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark UITableViewDelegate

#pragma mark MITNewsStoryDetailPagingDelegate

- (MITNewsStory*)newsDetailController:(MITNewsStoryDetailController*)storyDetailController storyAfterStory:(MITNewsStory*)story
{
#warning find better way to implement
    for (int i = 0 ; i < [self.stories count] ; i ++) {
        MITNewsStory *storyFromArray = [self.stories objectAtIndex:i];
        if ([story.identifier isEqualToString:storyFromArray.identifier]) {
            if ([self.stories count] > i + 1) {
                
                if (storyDetailController) {
                    [storyDetailController setStory:[self.stories objectAtIndex:i + 1]];
                } else {
                    return [self.stories objectAtIndex:i + 1];
                }
            }
        }
    };
    
    return nil;
}

- (MITNewsStory*)newsDetailController:(MITNewsStoryDetailController*)storyDetailController storyBeforeStory:(MITNewsStory*)story
{
    return nil;
}

- (BOOL)newsDetailController:(MITNewsStoryDetailController*)storyDetailController canPageToStory:(MITNewsStory*)story
{
    return nil;
}

- (void)newsDetailController:(MITNewsStoryDetailController*)storyDetailController didPageToStory:(MITNewsStory*)story
{

}

@end
