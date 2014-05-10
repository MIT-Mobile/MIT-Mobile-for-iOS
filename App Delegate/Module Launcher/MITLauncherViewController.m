#import "MITLauncherViewController.h"
#import "MITLauncherViewCell.h"
#import "MITAdditions.h"

static NSString* const MITLauncherCellIdentifier = @"LauncherCellIdentifier";

@interface MITLauncherViewController () <UICollectionViewDelegateFlowLayout>
@property (nonatomic) MITLauncherStyle style;

@end

@implementation MITLauncherViewController

- (instancetype)initWithStyle:(MITLauncherStyle)style
{
    UICollectionViewLayout *layout = nil;
    
    switch (style) {
        case MITLauncherStyleGrid: {
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            layout = flowLayout;
        } break;
            
        case MITLauncherStyleList: {
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            layout = flowLayout;
        } break;
    }
    
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _style = style;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_style == MITLauncherStyleList) {
        [self.collectionView registerNib:[UINib nibWithNibName:@"LauncherModuleListCell" bundle:nil] forCellWithReuseIdentifier:MITLauncherCellIdentifier];
    } else if (_style == MITLauncherStyleGrid) {
        [self.collectionView registerNib:[UINib nibWithNibName:@"LauncherModuleGridCell" bundle:nil] forCellWithReuseIdentifier:MITLauncherCellIdentifier];
    }

    self.collectionView.contentInset = UIEdgeInsetsMake(8.,8.,0.,8.);
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.style == MITLauncherStyleGrid) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
        flowLayout.itemSize = CGSizeMake(72., 86.);
        flowLayout.minimumLineSpacing = 6.;
        flowLayout.minimumInteritemSpacing = 4.;
    } else {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
        CGRect collectionViewBounds = UIEdgeInsetsInsetRect(self.collectionView.bounds,flowLayout.sectionInset);
        flowLayout.itemSize = CGSizeMake(CGRectGetWidth(collectionViewBounds) - 32., 60.);
    }

    // This is called last since viewWillAppear: will reload the
    // collection view and we need to ensure the sizes are setup
    // correctly before trying to show anything.
    [super viewWillAppear:animated];


    self.collectionView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor mit_backgroundColor];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegation
#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInLauncher:self];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MITLauncherCellIdentifier forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[MITLauncherViewCell class]]) {
        MITLauncherViewCell *launcherCell = (MITLauncherViewCell*)cell;

        if (self.style == MITLauncherStyleGrid) {
            launcherCell.shouldUseShortModuleNames = YES;
        }

        MITModule *module = [self.dataSource launcher:self moduleAtIndexPath:indexPath];
        launcherCell.module = module;
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate launcher:self didSelectModuleAtIndexPath:indexPath];
}

@end
