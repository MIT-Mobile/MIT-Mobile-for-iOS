#import "MITNewsiPadViewController.h"

typedef NS_ENUM(NSInteger, MITNewsPadStyle) {
    MITNewsPadStyleInvalid = -1,
    MITNewsPadStyleGrid = 0,
    MITNewsPadStyleList
};

@interface MITNewsiPadViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UICollectionViewController *gridViewController;
@property (nonatomic, weak) IBOutlet UITableViewController *listViewController;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) UIViewController *activeViewController;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
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
- (UICollectionViewController *)gridViewController
{
    UICollectionViewController *gridViewController = _gridViewController;
    
    if (!gridViewController) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        gridViewController = [[UICollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
        gridViewController.collectionView.dataSource = self;
        gridViewController.collectionView.delegate = self;
        gridViewController.collectionView.backgroundView = nil;
        gridViewController.collectionView.backgroundColor = [UIColor redColor];
        
        _gridViewController = gridViewController;
    }
    
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
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark UICollectionViewDelegate

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



@end
