#import "MITLauncherGridViewController.h"
#import "MITLauncherGridViewCell.h"
#import "MITAdditions.h"
#import "MITLauncher.h"

static NSString* const MITLauncherModuleGridCellIdentifier = @"LauncherModuleGridCell";
static NSString* const MITLauncherModuleGridNibName = @"LauncherModuleGridCell";

@interface MITLauncherGridViewController () <UICollectionViewDelegateFlowLayout>


@end

@implementation MITLauncherGridViewController
- (instancetype)init
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(72., 86.);
    flowLayout.minimumLineSpacing = 6.;
    flowLayout.minimumInteritemSpacing = 4.;
    
    self = [super initWithCollectionViewLayout:flowLayout];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!(self.storyboard || self.nibName)) {
        self.collectionView.contentInset = UIEdgeInsetsMake(8.,8.,0.,8.);
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.view.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITLauncherModuleGridNibName bundle:nil] forCellWithReuseIdentifier:MITLauncherModuleGridCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MITLauncherModuleGridCellIdentifier forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[MITLauncherGridViewCell class]]) {
        MITLauncherGridViewCell *launcherCell = (MITLauncherGridViewCell*)cell;

        MITModule *module = [self.dataSource launcher:self moduleAtIndexPath:indexPath];
        launcherCell.module = module;
        launcherCell.shouldUseShortModuleNames = YES;
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate launcher:self didSelectModuleAtIndexPath:indexPath];
}

@end
