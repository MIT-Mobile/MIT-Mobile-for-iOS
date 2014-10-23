#import "MITLibrariesYourAccountGridViewControllerPad.h"
#import "MITLibrariesItemLoanFineCollectionCell.h"
#import "MITLibrariesItemHoldCollectionCell.h"
#import "TopAlignedStickyHeaderCollectionViewFlowLayout.h"
#import "MITLibrariesUser.h"
#import "MITLibrariesYourAccountItemDetailViewController.h"

typedef NS_ENUM(NSInteger, MITAccountListSection) {
    MITAccountListSectionLoans = 0,
    MITAccountListSectionFines,
    MITAccountListSectionHolds
};

static NSString * const kLoanFineCollectionCellIdentifier = @"kLoanFineCollectionCellIdentifier";
static NSString * const kHoldCollectionCellIdentifier = @"kHoldCollectionCellIdentifier";

static CGFloat const kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding = 20.0;

@interface MITLibrariesYourAccountGridViewControllerPad () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation MITLibrariesYourAccountGridViewControllerPad

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesItemLoanFineCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:kLoanFineCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesItemHoldCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:kHoldCollectionCellIdentifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.collectionViewLayout = [[TopAlignedStickyHeaderCollectionViewFlowLayout alloc] init];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.collectionView reloadData];
}

- (void)setUser:(MITLibrariesUser *)user
{
    _user = user;
    
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.user) {
        return 3;
    } else {
        return 0;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.user) {
        return 0;
    }
    
    switch (section) {
        case MITAccountListSectionLoans:
            return self.user.loans.count;
            break;
        case MITAccountListSectionFines:
            return self.user.fines.count;
            break;
        case MITAccountListSectionHolds:
            return self.user.holds.count;
            break;
        default:
            return 0;
            break;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            MITLibrariesItemLoanFineCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kLoanFineCollectionCellIdentifier forIndexPath:indexPath];
            [cell setContent:self.user.loans[indexPath.row]];
            return cell;
            break;
        }
        case MITAccountListSectionFines: {
            MITLibrariesItemLoanFineCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kLoanFineCollectionCellIdentifier forIndexPath:indexPath];
            [cell setContent:self.user.fines[indexPath.row]];
            return cell;
            break;
        }
        case MITAccountListSectionHolds: {
            MITLibrariesItemHoldCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kHoldCollectionCellIdentifier forIndexPath:indexPath];
            [cell setContent:self.user.holds[indexPath.row]];
            return cell;
            break;
        }
        default:
            return [UICollectionViewCell new];
            break;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat interItemSpacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    CGFloat cellWidth = 0;
    NSInteger numberOfColumns = 0;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        numberOfColumns = 2;
    } else {
        numberOfColumns = 3;
    }
    
    cellWidth = (collectionView.bounds.size.width - (2 * kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding) - ((numberOfColumns - 1) * interItemSpacing)) / numberOfColumns;
    
    CGFloat cellHeight = 0;
    
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            cellHeight = [MITLibrariesItemLoanFineCollectionCell heightForContent:self.user.loans[indexPath.row] width:cellWidth];
            break;
        }
        case MITAccountListSectionFines: {
            cellHeight = [MITLibrariesItemLoanFineCollectionCell heightForContent:self.user.fines[indexPath.row] width:cellWidth];
            break;
        }
        case MITAccountListSectionHolds: {
            cellHeight = [MITLibrariesItemHoldCollectionCell heightForContent:self.user.holds[indexPath.row] width:cellWidth];
            break;
        }
    }
    
    return CGSizeMake(floor(cellWidth), cellHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding, 10, kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    MITLibrariesMITItem *selectedItem = nil;
    switch (indexPath.section) {
        case MITAccountListSectionLoans: {
            selectedItem = self.user.loans[indexPath.row];
            break;
        }
        case MITAccountListSectionFines: {
            selectedItem = self.user.fines[indexPath.row];
            break;
        }
        case MITAccountListSectionHolds: {
            selectedItem = self.user.holds[indexPath.row];
            break;
        }
        default:
            return;
            break;
    }
    
    MITLibrariesYourAccountItemDetailViewController *detailVC = [[MITLibrariesYourAccountItemDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.item = selectedItem;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:^{}];
}

@end
