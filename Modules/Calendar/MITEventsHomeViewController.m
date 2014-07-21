#import "MITEventsHomeViewController.h"
#import "MITDayOfTheWeekCell.h"
#import "UIKit+MITAdditions.h"

static NSString *const kMITDayOfTheWeekCell = @"MITDayOfTheWeekCell";

@interface MITEventsHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *dayPickerContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *dayPickerCollectionView;

@property (weak, nonatomic) UIView *navBarSeparatorView;

@end

@implementation MITEventsHomeViewController

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
    // Do any additional setup after loading the view from its nib.
   // self.view.backgroundColor = [UIColor mit_backgroundColor];
    [self setupExtendedNavBar];
    [self setupDayPickerCollectionView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupExtendedNavBar
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    self.navBarSeparatorView = [self findHairlineImageViewUnder:navigationBar];
    navigationBar.opaque = YES;
    navigationBar.translucent = NO;
    [navigationBar setBarTintColor:[UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0]];
    self.dayPickerContainerView.backgroundColor = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}


- (void)setupDayPickerCollectionView
{
    self.dayPickerCollectionView.backgroundColor = [UIColor clearColor];
    
    UINib *cellNib = [UINib nibWithNibName:kMITDayOfTheWeekCell bundle:nil];
    [self.dayPickerCollectionView registerNib:cellNib forCellWithReuseIdentifier:kMITDayOfTheWeekCell];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navBarSeparatorView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navBarSeparatorView.hidden = NO;
}

#pragma mark - Day of the week Collection View Datasource/Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITDayOfTheWeekCell *cell = [self.dayPickerCollectionView dequeueReusableCellWithReuseIdentifier:kMITDayOfTheWeekCell
                                                                                        forIndexPath:indexPath];
    
    cell.dayOfTheWeek = indexPath.row;
    cell.state = MITDayOfTheWeekStateUnselected;
    return cell;
}


@end
