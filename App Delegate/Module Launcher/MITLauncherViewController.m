#import "MITLauncherViewController.h"
#import "MITLauncherViewCell.h"

static NSString* const MITLauncherCellIdentifier = @"LauncherCellIdentifier";

@interface MITLauncherViewController () <UICollectionViewDelegateFlowLayout>
@property (nonatomic) MITLauncherStyle style;

@end

@implementation MITLauncherViewController

- (instancetype)initWithStyle:(MITLauncherStyle)style
{
    UICollectionViewLayout *layout = nil;
    
    switch (style) {
        case MITLauncherStyleGrid:
            layout = [[UICollectionViewFlowLayout alloc] init];
            break;
            
        case MITLauncherStyleList: {
            NSAssert(NO,@"Not implemented yet");
        } // Fall Through
        case MITLauncherStyleCustom:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"initWithStyle: does not support the use of MITLauncherStyleCustom. If you wish to use your own layout, call initWithCollectionViewLayout:" userInfo:nil];
    }
    
    self = [sup initWithCollectionViewLayout:nil];
    if (self) {
        _style = style;
    }
    
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout
{
    self = [super initWithCollectionViewLayout:layout];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_style == MITLauncherStyleGrid) {
        [self.collectionView registerNib:[UINib nibWithNibName:@"LauncherModuleGridCell" bundle:nil] forCellWithReuseIdentifier:MITLauncherCellIdentifier];
    } else {
        [self.collectionView registerNib:[UINib nibWithNibName:@"LauncherModuleListCell" bundle:nil] forCellWithReuseIdentifier:MITLauncherCellIdentifier];
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(72.,82.);
}

@end
