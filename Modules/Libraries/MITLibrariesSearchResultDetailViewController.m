#import "MITLibrariesSearchResultDetailViewController.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesItemDetailLineCell.h"
#import "MITLibrariesHoldingLibraryHeaderCell.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesHolding.h"
#import "MITLibrariesAvailability.h"
#import "MITLibrariesHoldingLibraryHeaderCopyInfoCell.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesAvailabilityDetailViewController.h"
#import "MITLibrariesCitationsViewController.h"

static NSString * const kDefaultCellIdentifier = @"kDefaultCellIdentifier";
static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kItemDetailLineCellIdentifier = @"kItemDetailLineCellIdentifier";
static NSString * const kHoldingLibraryHeaderCellIdentifier = @"kHoldingLibraryHeaderCellIdentifier";
static NSString * const kHoldingLibraryCopyCellIdentifier = @"kHoldingLibraryCopyCellIdentifier";
static NSString * const kHoldingLibraryViewAllCellIdentifier = @"kHoldingLibraryViewAllCellIdentifier";

static NSInteger const kBookInfoSection = 0;
static NSInteger const kCitationsSection = 1;
static NSInteger const kLoadingCellSection = 1;
static NSInteger const kLibraryHoldingsSection = 2;
static NSInteger const kBLCHoldingsSection = 3;

static NSString * const kItemLineTitleKey = @"kItemLineTitleKey";
static NSString * const kItemLineDetailKey = @"kItemLineDetailKey";

static NSString * const kAvailabilityLocationKey = @"kAvailabilityLocationKey";
static NSString * const kAvailabilitiesKey = @"kAvailabilitiesKey";
static NSString * const kAvailableCopiesNumberKey = @"kAvailableCopiesNumberKey";
static NSString * const kAvailableCopiesForDisplayKey = @"kAvailableCopiesForDisplayKey";

@interface MITLibrariesSearchResultDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *itemDetailLines;
@property (nonatomic, strong) MITLibrariesHolding *mitHolding;
@property (nonatomic, strong) NSArray *availabilitiesByLibrary;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation MITLibrariesSearchResultDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self registerCells];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerCells
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellIdentifier];
    
    UINib *librariesItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.tableView registerNib:librariesItemCellNib forCellReuseIdentifier:kItemHeaderCellIdentifier];
    
    UINib *librariesItemDetailCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemDetailLineCell class]) bundle:nil];
    [self.tableView registerNib:librariesItemDetailCellNib forCellReuseIdentifier:kItemDetailLineCellIdentifier];
    
    UINib *librariesHoldingHeaderCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesHoldingLibraryHeaderCell class]) bundle:nil];
    [self.tableView registerNib:librariesHoldingHeaderCellNib forCellReuseIdentifier:kHoldingLibraryHeaderCellIdentifier];
    
    UINib *librariesHoldingCopyInfoCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesHoldingLibraryHeaderCopyInfoCell class]) bundle:nil];
    [self.tableView registerNib:librariesHoldingCopyInfoCellNib forCellReuseIdentifier:kHoldingLibraryCopyCellIdentifier];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kHoldingLibraryViewAllCellIdentifier];
}

- (void)hydrateCurrentItem
{
    self.isLoading = YES;
    [self.tableView reloadData];
    
    [MITLibrariesWebservices getItemDetailsForItem:self.worldcatItem completion:^(MITLibrariesWorldcatItem *item, NSError *error) {
        if (error) {
            self.isLoading = NO;
            [self.tableView reloadData];
        } else {
            _worldcatItem = item;
            [self recreateItemDetailLines];
            [self recreateMITAvailability];
            self.isLoading = NO;
            [self.tableView reloadData];
        }
    }];
}

- (void)recreateItemDetailLines
{
    NSMutableArray *newItemDetailLines = [NSMutableArray arrayWithCapacity:3];
    
    if ([self.worldcatItem formatsString].length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"Format",
                                        kItemLineDetailKey: [self.worldcatItem formatsString]}];
    }
    
    if ([self.worldcatItem publishersString].length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"Publisher",
                                        kItemLineDetailKey: [self.worldcatItem publishersString]}];
    }
    
    if ([self.worldcatItem firstSummaryString].length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"Description",
                                        kItemLineDetailKey: [self.worldcatItem firstSummaryString]}];
    }
    
    self.itemDetailLines = [NSArray arrayWithArray:newItemDetailLines];
}

- (void)recreateMITAvailability
{
    for (MITLibrariesHolding *holding in self.worldcatItem.holdings) {
        if ([holding.code isEqualToString:@"MYG"]) {
            self.mitHolding = holding;
            break;
        }
    }
    
    NSMutableDictionary *availabilitiesInLibraries = [NSMutableDictionary dictionary];
    for (MITLibrariesAvailability *availability in self.mitHolding.availability) {
        NSMutableArray *availabilitiesInCurrentLibrary = [availabilitiesInLibraries objectForKey:availability.location];
        if (!availabilitiesInCurrentLibrary) {
            availabilitiesInCurrentLibrary = [NSMutableArray array];
        }
        
        [availabilitiesInCurrentLibrary addObject:availability];
        [availabilitiesInLibraries setObject:availabilitiesInCurrentLibrary forKey:availability.location];
    }
    
    NSMutableArray *newAvailabilitiesByLibrary = [NSMutableArray array];
    for (id key in [availabilitiesInLibraries allKeys]) {
        NSArray *availabilities = [availabilitiesInLibraries objectForKey:key];
        
        NSInteger availableCopies = 0;
        NSMutableArray *firstAvailableCopiesForDisplay = [NSMutableArray array];
        for (MITLibrariesAvailability *availability in availabilities) {
            if (availability.available) {
                availableCopies++;
                if (firstAvailableCopiesForDisplay.count < 3) {
                    [firstAvailableCopiesForDisplay addObject:availability];
                }
            }
        }
        
        [newAvailabilitiesByLibrary addObject:@{kAvailabilityLocationKey: key,
                                                kAvailabilitiesKey: availabilities,
                                                kAvailableCopiesNumberKey: [NSNumber numberWithInteger:availableCopies],
                                                kAvailableCopiesForDisplayKey: [NSArray arrayWithArray:firstAvailableCopiesForDisplay]}];
    }
    
    self.availabilitiesByLibrary = [NSArray arrayWithArray:newAvailabilitiesByLibrary];
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isLoading) {
        return 2;
    } else {
        return 4;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isLoading) {
        switch (section) {
            case kBookInfoSection: {
                return 1 + self.itemDetailLines.count;
                break;
            }
            case kLoadingCellSection: {
                return 1;
                break;
            }
            default: {
                return 0;
            }
        }
    } else {
        switch (section) {
            case kBookInfoSection: {
                return 1 + self.itemDetailLines.count;
                break;
            }
            case kCitationsSection: {
                return self.worldcatItem.citations.count > 0 ? 1 : 0;
                break;
            }
            case kLibraryHoldingsSection: {
                return [self totalHoldingLibrariesRowCount];
                break;
            }
            case kBLCHoldingsSection: {
                return 1;
                break;
            }
            default: {
                return 0;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoading) {
        switch (indexPath.section) {
            case kBookInfoSection: {
                return [self bookInfoSectionCellForRow:indexPath.row];
                break;
            }
            case kLoadingCellSection: {
                UITableViewCell *loadingCell = [self.tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
                loadingCell.accessoryView = nil;
                loadingCell.accessoryType = UITableViewCellAccessoryNone;
                loadingCell.textLabel.text = @"Loading...";
                return loadingCell;
                break;
            }
            default: {
                return [UITableViewCell new];
            }
        }
    } else {
        switch (indexPath.section) {
            case kBookInfoSection: {
                return [self bookInfoSectionCellForRow:indexPath.row];
                break;
            }
            case kCitationsSection: {
                return [self citationsSectionCellForRow:indexPath.row];
                break;
            }
            case kLibraryHoldingsSection: {
                return [self libraryHoldingsSectionCellForLibraryHoldingsIndexPath:[self holdingsIndexPathForLibraryHoldingsRow:indexPath.row]];
                break;
            }
            case kBLCHoldingsSection: {
                return [self blcHoldingsSectionCellForRow:indexPath.row];
                break;
            }
            default: {
                return [UITableViewCell new];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoading) {
        switch (indexPath.section) {
            case kBookInfoSection: {
                return [self bookInfoSectionHeightForRow:indexPath.row];
                break;
            }
            case kLoadingCellSection: {
                return 44;
                break;
            }
            default: {
                return 0;
            }
        }
    } else {
        switch (indexPath.section) {
            case kBookInfoSection: {
                return [self bookInfoSectionHeightForRow:indexPath.row];
                break;
            }
            case kCitationsSection: {
                return 44;
                break;
            }
            case kLibraryHoldingsSection: {
                return [self libraryHoldingsSectionHeightForLibraryHoldingsIndexPath:[self holdingsIndexPathForLibraryHoldingsRow:indexPath.row]];
                break;
            }
            case kBLCHoldingsSection: {
                return 44;
                break;
            }
            default: {
                return 0;
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.isLoading) {
        return;
    }
    
    switch (indexPath.section) {
        case kBookInfoSection: {
            // Nothing to do here
            return;
            break;
        }
        case kCitationsSection: {
            MITLibrariesCitationsViewController *citationsVC = [[MITLibrariesCitationsViewController alloc] initWithNibName:nil bundle:nil];
            citationsVC.worldcatItem = self.worldcatItem;
            [self.navigationController pushViewController:citationsVC animated:YES];
            break;
        }
        case kLibraryHoldingsSection: {
            [self libraryHoldingsSectionRowTapped:indexPath.row];
            break;
        }
        case kBLCHoldingsSection: {
            // TODO: Push BLC Holdings screen
            break;
        }
        default: {
            return;
        }
    }
}

- (void)libraryHoldingsSectionRowTapped:(NSInteger)row
{
    if (row == 0) {
        NSURL *requestURL = [NSURL URLWithString:self.mitHolding.requestUrl];
        
        if ([[UIApplication sharedApplication] canOpenURL:requestURL]) {
            [[UIApplication sharedApplication] openURL:requestURL];
        }
    } else {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:kLibraryHoldingsSection]];
        if ([selectedCell.reuseIdentifier isEqualToString:kHoldingLibraryViewAllCellIdentifier]) {
            NSIndexPath *libraryHoldingsIndexPath = [self holdingsIndexPathForLibraryHoldingsRow:row];
            NSDictionary *availabilityInfo = self.availabilitiesByLibrary[libraryHoldingsIndexPath.section - 1];
            
            MITLibrariesAvailabilityDetailViewController *availabilityVC = [[MITLibrariesAvailabilityDetailViewController alloc] initWithNibName:nil bundle:nil];
            availabilityVC.worldcatItem = self.worldcatItem;
            availabilityVC.libraryName = availabilityInfo[kAvailabilityLocationKey];
            availabilityVC.availabilitiesInLibrary = availabilityInfo[kAvailabilitiesKey];
            
            [self.navigationController pushViewController:availabilityVC animated:YES];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kBookInfoSection: {
            return nil;
            break;
        }
        case kCitationsSection: {
            return nil;
            break;
        }
        case kLibraryHoldingsSection: {
            return @"MIT Libraries";
            break;
        }
        case kBLCHoldingsSection: {
            return @"Boston Library Consortium";
            break;
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kBookInfoSection) {
        return 0.0001f;
    } else if (section == kCitationsSection) {
        return 25;
    } else {
        return 35;
    }
}

#pragma mark - Custom Cell Creation

- (UITableViewCell *)bookInfoSectionCellForRow:(NSInteger)row
{
    if (row == 0) {
        MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
        [itemHeaderCell setContent:self.worldcatItem];
        itemHeaderCell.showsSeparator = NO;
        return itemHeaderCell;
    } else {
        MITLibrariesItemDetailLineCell *detailLineCell = [self.tableView dequeueReusableCellWithIdentifier:kItemDetailLineCellIdentifier];
        NSDictionary *itemLineDictionary = self.itemDetailLines[row - 1];
        detailLineCell.lineTitleLabel.text = [itemLineDictionary objectForKey:kItemLineTitleKey];
        detailLineCell.lineDetailLabel.text = [itemLineDictionary objectForKey:kItemLineDetailKey];
        return detailLineCell;
    }
}

- (UITableViewCell *)citationsSectionCellForRow:(NSInteger)row
{
    UITableViewCell *citationsCell = [self.tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
    citationsCell.textLabel.text = @"Citations";
    citationsCell.accessoryView = nil;
    citationsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return citationsCell;
}

- (UITableViewCell *)blcHoldingsSectionCellForRow:(NSInteger)row
{
    UITableViewCell *blcHoldingsCell = [self.tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
    blcHoldingsCell.textLabel.text = @"View Holdings";
    blcHoldingsCell.accessoryView = nil;
    blcHoldingsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return blcHoldingsCell;
}

#pragma mark - Custom Cell Heights

- (CGFloat)bookInfoSectionHeightForRow:(NSInteger)row
{
    if (row == 0) {
        CGFloat height = [MITLibrariesWorldcatItemCell heightForContent:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
        return height;
    } else {
        NSDictionary *itemLineDictionary = self.itemDetailLines[row - 1];
        CGFloat height = [MITLibrariesItemDetailLineCell heightForTitle:[itemLineDictionary objectForKey:kItemLineTitleKey] detail:[itemLineDictionary objectForKey:kItemLineDetailKey] tableViewWidth:self.tableView.bounds.size.width];
        return height;
    }
}

#pragma mark - Library Holdings Section Methods

// We create each library's holdings info from multiple cells, but it makes sense to think about each library as its own section
// This should be more efficient and have less weird behavior than actually using another tableview inside the main tableview, I think

- (UITableViewCell *)libraryHoldingsSectionCellForLibraryHoldingsIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *requestCell = [self.tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
        requestCell.textLabel.text = @"Request Item";
        requestCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        return requestCell;
    } else {
        NSDictionary *availabilityInfo = self.availabilitiesByLibrary[indexPath.section - 1];
        
        if (indexPath.row == 0) {
            // Header cell
            NSString *locationName = [availabilityInfo objectForKey:kAvailabilityLocationKey];
            NSArray *availabilities = [availabilityInfo objectForKey:kAvailabilitiesKey];
            NSInteger totalCopiesNumber = availabilities.count;
            NSInteger availableCopiesNumber = [[availabilityInfo objectForKey:kAvailableCopiesNumberKey] integerValue];
            
            MITLibrariesHoldingLibraryHeaderCell *holdingHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryHeaderCellIdentifier];
            holdingHeaderCell.libraryNameLabel.text = locationName;
            holdingHeaderCell.libraryHoursLabel.text = @"Put hours here";
            holdingHeaderCell.availableCopiesLabel.text = [NSString stringWithFormat:@"%i of %i available", availableCopiesNumber, totalCopiesNumber];
            return holdingHeaderCell;
        }
        
        NSArray *availableCopiesToDisplay = [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey];
        
        if (indexPath.row - 1 < availableCopiesToDisplay.count) {
            // Holding availability detail cell
            MITLibrariesAvailability *availability = availableCopiesToDisplay[indexPath.row - 1];
            
            MITLibrariesHoldingLibraryHeaderCopyInfoCell *copyInfoCell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryCopyCellIdentifier];
            [copyInfoCell setAvailability:availability];
            return copyInfoCell;
        }
        
        // If we get here, this is the last cell: "view all"
        UITableViewCell *viewAllCell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryViewAllCellIdentifier];
        viewAllCell.textLabel.text = @"View all";
        viewAllCell.textLabel.textColor = [UIColor mit_tintColor];
        return viewAllCell;
    }
}

- (NSIndexPath *)holdingsIndexPathForLibraryHoldingsRow:(NSInteger)row
{
    NSInteger numberOfRowsInPreviousSections = 0;
    
    for (NSInteger section = 0; section < [self numberOfSectionsInLibraryHoldingsSection]; section++) {
        NSInteger numberOfRowsInCurrentSection = [self numberOfRowsInLibraryHoldingsSection:section];
        
        if (row < numberOfRowsInPreviousSections + numberOfRowsInCurrentSection) {
            return [NSIndexPath indexPathForRow:(row - numberOfRowsInPreviousSections) inSection:section];
        } else {
            numberOfRowsInPreviousSections += numberOfRowsInCurrentSection;
        }
    }
    
    // If we get here, then the row is too high
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (NSInteger)numberOfSectionsInLibraryHoldingsSection
{
    return 1 + self.availabilitiesByLibrary.count;
}

- (NSInteger)numberOfRowsInLibraryHoldingsSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        NSInteger rowsInSection = 2; // One for the header, one for the "view all" cell
        NSDictionary *availabilityInfo = self.availabilitiesByLibrary[section - 1];
        NSArray *availableCopiesToDisplay = [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey];
        rowsInSection += availableCopiesToDisplay.count;
        return rowsInSection;
    }
}

- (NSInteger)totalHoldingLibrariesRowCount
{
    NSInteger totalRows = 0;
    
    for (NSInteger section = 0; section < [self numberOfSectionsInLibraryHoldingsSection]; section++) {
        totalRows += [self numberOfRowsInLibraryHoldingsSection:section];
    }
    
    return totalRows;
}

- (CGFloat)libraryHoldingsSectionHeightForLibraryHoldingsIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 44;
    } else {
        NSDictionary *availabilityInfo = self.availabilitiesByLibrary[indexPath.section - 1];
        
        if (indexPath.row == 0) {
            // Header cell
            return 75;
        }
        
        NSArray *availableCopiesToDisplay = [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey];
        
        if (indexPath.row - 1 < availableCopiesToDisplay.count) {
            // Holding availability detail cell
            MITLibrariesAvailability *availability = availableCopiesToDisplay[indexPath.row - 1];
            
            return [MITLibrariesHoldingLibraryHeaderCopyInfoCell heightForItem:availability tableViewWidth:self.tableView.bounds.size.width];
        }
        
        // If we get here, this is the last cell: "view all"
        return 44;
    }
}

@end
