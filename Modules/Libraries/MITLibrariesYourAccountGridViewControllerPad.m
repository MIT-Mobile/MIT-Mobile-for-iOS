#import "MITLibrariesYourAccountGridViewControllerPad.h"
#import "MITLibrariesItemLoanFineCollectionCell.h"
#import "MITLibrariesItemHoldCollectionCell.h"
#import "TopAlignedStickyHeaderCollectionViewFlowLayout.h"
#import "MITLibrariesUser.h"
#import "MITLibrariesYourAccountItemDetailViewController.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"
#import "MITLibrariesYourAccountCollectionViewHeader.h"

typedef NS_ENUM(NSInteger, MITAccountListSection) {
    MITAccountListSectionLoans = 0,
    MITAccountListSectionFines,
    MITAccountListSectionHolds
};

static NSString * const kLoanFineCollectionCellIdentifier = @"kLoanFineCollectionCellIdentifier";
static NSString * const kHoldCollectionCellIdentifier = @"kHoldCollectionCellIdentifier";
static NSString * const kCollectionHeaderIdentifier = @"kCollectionHeaderIdentifier";

static CGFloat const kMITLibrariesYourAccountGridCollectionViewSectionHorizontalPadding = 30.0;

@interface MITLibrariesYourAccountGridViewControllerPad () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionReusableView *loansHeader;
@property (nonatomic, strong) UICollectionReusableView *finesHeader;
@property (nonatomic, strong) UICollectionReusableView *holdsHeader;
@property (nonatomic, assign) CGFloat previousCollectionViewContentOffsetY;

@end

@implementation MITLibrariesYourAccountGridViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesItemLoanFineCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:kLoanFineCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesItemHoldCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:kHoldCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesYourAccountCollectionViewHeader class]) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kCollectionHeaderIdentifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    TopAlignedStickyHeaderCollectionViewFlowLayout *customCollectionViewLayout = [[TopAlignedStickyHeaderCollectionViewFlowLayout alloc] init];
    self.collectionView.collectionViewLayout = customCollectionViewLayout;
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
    
    cellWidth = (collectionView.bounds.size.width - (2 * kMITLibrariesYourAccountGridCollectionViewSectionHorizontalPadding) - ((numberOfColumns - 1) * interItemSpacing)) / numberOfColumns;
    
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
    return UIEdgeInsetsMake(10, kMITLibrariesYourAccountGridCollectionViewSectionHorizontalPadding, 10, kMITLibrariesYourAccountGridCollectionViewSectionHorizontalPadding);
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

#pragma mark - CollectionView Header Methods

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        MITLibrariesYourAccountCollectionViewHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kCollectionHeaderIdentifier forIndexPath:indexPath];
        
        NSAttributedString *headerText = nil;
        
        switch (indexPath.section) {
            case MITAccountListSectionLoans: {
                headerText = [self loansHeaderString];
                self.loansHeader = header;
                break;
            }
            case MITAccountListSectionFines: {
                headerText = [self finesHeaderString];
                self.finesHeader = header;
                break;
            }
            case MITAccountListSectionHolds: {
                headerText = [self holdsHeaderString];
                self.holdsHeader = header;
                break;
            }
        }
        
        [header setAttributedString:headerText];
        
        header.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];

        return header;
    } else {
        return [UICollectionReusableView new];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    NSAttributedString *headerText = nil;
    
    switch (section) {
        case MITAccountListSectionLoans: {
            headerText = [self loansHeaderString];
            break;
        }
        case MITAccountListSectionFines: {
            headerText = [self finesHeaderString];
            break;
        }
        case MITAccountListSectionHolds: {
            headerText = [self holdsHeaderString];
            break;
        }
    }
    
    CGFloat headerWidth = collectionView.bounds.size.width;
    CGFloat headerHeight = [MITLibrariesYourAccountCollectionViewHeader heightForAttributedString:headerText width:headerWidth];
    return CGSizeMake(headerWidth, headerHeight);
}

#pragma mark - Account Header Attributed Strings

- (NSAttributedString *)loansHeaderString
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Loans " attributes:@{NSFontAttributeName : [UIFont librariesTitleStyleFont]}];
    
    [baseString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu items, ", (unsigned long)self.user.loans.count]
                                                                              attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                           NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
    
    NSAttributedString *overdueString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld overdue", (long)self.user.overdueItemsCount]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                     NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:overdueString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

- (NSAttributedString *)finesHeaderString
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d/yyyy"];
    }
    
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Fines " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
    
    [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:self.user.formattedBalance
                                                                       attributes:@{NSForegroundColorAttributeName : [UIColor mit_closedRedColor],
                                                                                    NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}]];
    
    NSAttributedString *detailsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" as of %@.\nPayable at any MIT library service desk. TechCASH accepted only at Hayden Library.", [dateFormatter stringFromDate:self.finesUpdatedDate]]
                                                                        attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                     NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:detailsString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

- (NSAttributedString *)holdsHeaderString
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithString:@"Holds " attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0]}];
    
    [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu holds, ", (unsigned long)self.user.holds.count]
                                                                       attributes:@{NSForegroundColorAttributeName : [UIColor mit_greyTextColor],
                                                                                    NSFontAttributeName : [UIFont systemFontOfSize:14.0]}]];
    
    NSAttributedString *readyForPickupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld ready for pickup", (long)self.user.readyForPickupCount]
                                                                               attributes:@{NSForegroundColorAttributeName : [UIColor mit_openGreenColor],
                                                                                            NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0]}];
    
    [baseString appendAttributedString:readyForPickupString];
    
    return [[NSAttributedString alloc] initWithAttributedString:baseString];
}

@end
