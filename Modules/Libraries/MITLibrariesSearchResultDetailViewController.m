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

static NSString * const kDefaultCellIdentifier = @"kDefaultCellIdentifier";
static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kItemDetailLineCellIdentifier = @"kItemDetailLineCellIdentifier";
static NSString * const kHoldingLibraryHeaderCellIdentifier = @"kHoldingLibraryHeaderCellIdentifier";
static NSString * const kHoldingLibraryCopyCellIdentifier = @"kHoldingLibraryCopyCellIdentifier";
static NSString * const kHoldingLibraryViewAllCellIdentifier = @"kHoldingLibraryViewAllCellIdentifier";

static NSInteger const kBookInfoSection = 0;
static NSInteger const kCitationsSection = 1;
static NSInteger const kHoldingLibrariesSection = 2;
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

- (void)setWorldcatItem:(MITLibrariesWorldcatItem *)worldcatItem
{
    _worldcatItem = worldcatItem;
    [self.tableView reloadData];
    
    [MITLibrariesWebservices getItemDetailsForItem:worldcatItem completion:^(MITLibrariesWorldcatItem *item, NSError *error) {
        if (error) {
            // Show something?
        } else {
            _worldcatItem = item;
            [self recreateItemDetailLines];
            [self recreateMITAvailability];
            [self.tableView reloadData];
            
//            for (MITLibrariesHolding *holding in item.holdings) {
//                NSLog(@"\ncode: %@\nlibrary: %@\naddress: %@count: %i\nurl: %@\n\n", holding.code, holding.library, holding.address, holding.count, holding.url);
//                for (MITLibrariesAvailability *availability in holding.availability) {
//                    NSLog(@"location: %@, collection: %@, callnum: %@, status: %@, available: %@", availability.location, availability.collection, availability.callNumber, availability.status, availability.available ? @"YES" : @"NO");
//                }
//            }
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kBookInfoSection: {
            return 1 + self.itemDetailLines.count;
            break;
        }
        case kCitationsSection: {
            return 1;
            break;
        }
        case kHoldingLibrariesSection: {
            return 1 + [self totalHoldingLibrariesRowCount];
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

- (NSInteger)totalHoldingLibrariesRowCount
{
    NSInteger totalRows = 0;
    for (NSDictionary *availabilityInfo in self.availabilitiesByLibrary) {
        totalRows++; // Account for header cell
        
        NSArray *availableCopiesToDisplay = [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey];
        totalRows += availableCopiesToDisplay.count;
        
        totalRows++; // Account for "View all" cell
    }
    
    return totalRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kBookInfoSection: {
            return [self bookInfoSectionCellForRow:indexPath.row];
            break;
        }
        case kCitationsSection: {
            return [self citationsSectionCellForRow:indexPath.row];
            break;
        }
        case kHoldingLibrariesSection: {
            return [self holdingLibrariesSectionCellForRow:indexPath.row];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kBookInfoSection: {
            return [self bookInfoSectionHeightForRow:indexPath.row];
            break;
        }
        case kCitationsSection: {
            return 44;
            break;
        }
        case kHoldingLibrariesSection: {
            return [self holdingLibrariesSectionHeightForRow:indexPath.row];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // TODO
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
        case kHoldingLibrariesSection: {
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

#pragma mark - Custom Cell Creation

- (UITableViewCell *)bookInfoSectionCellForRow:(NSInteger)row
{
    if (row == 0) {
        MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
        itemHeaderCell.item = self.worldcatItem;
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

- (UITableViewCell *)holdingLibrariesSectionCellForRow:(NSInteger)row
{
    if (row == 0) {
        UITableViewCell *requestCell = [self.tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
        requestCell.textLabel.text = @"Request Item";
        requestCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        return requestCell;
    } else {
        NSInteger adjustedRow = row - 1; // Adjust for the first "request item" cell in the section
        NSInteger totalRowsAccountedFor = 0;
        for (NSDictionary *availabilityInfo in self.availabilitiesByLibrary) {
            
            if (adjustedRow == totalRowsAccountedFor) {
                // return header for this availability info
                
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
            totalRowsAccountedFor++; // Account for header cell
            
            for (MITLibrariesAvailability *availability in [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey]) {
                if (adjustedRow == totalRowsAccountedFor) {
                    // return detail for this availability
                    
                    MITLibrariesHoldingLibraryHeaderCopyInfoCell *copyInfoCell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryCopyCellIdentifier];
                    [copyInfoCell setAvailability:availability];
                    return copyInfoCell;
                }
                totalRowsAccountedFor++;
            }
            
            if (adjustedRow == totalRowsAccountedFor) {
                // return view all button cell for this availability info
                
                UITableViewCell *viewAllCell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryViewAllCellIdentifier];
                viewAllCell.textLabel.text = @"View all";
                viewAllCell.textLabel.textColor = [UIColor mit_tintColor];
                return viewAllCell;
            }
            totalRowsAccountedFor++; // Account for "View all" cell
        }
    }
    
    // Should not get here, return blank cell to prevent crash if something went wrong!
    return [UITableViewCell new];
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
        CGFloat height = [MITLibrariesWorldcatItemCell heightForItem:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
        return height;
    } else {
        NSDictionary *itemLineDictionary = self.itemDetailLines[row - 1];
        CGFloat height = [MITLibrariesItemDetailLineCell heightForTitle:[itemLineDictionary objectForKey:kItemLineTitleKey] detail:[itemLineDictionary objectForKey:kItemLineDetailKey] tableViewWidth:self.tableView.bounds.size.width];
        return height;
    }
}

- (CGFloat)holdingLibrariesSectionHeightForRow:(NSInteger)row
{
    if (row == 0) {
        return 44;
    } else {
        NSInteger adjustedRow = row - 1; // Adjust for the first "request item" cell in the section
        NSInteger totalRowsAccountedFor = 0;
        for (NSDictionary *availabilityInfo in self.availabilitiesByLibrary) {
            
            if (adjustedRow == totalRowsAccountedFor) {
                // return header for this availability info
                return 75;
            }
            totalRowsAccountedFor++; // Account for header cell
            
            
            for (MITLibrariesAvailability *availability in [availabilityInfo objectForKey:kAvailableCopiesForDisplayKey]) {
                if (adjustedRow == totalRowsAccountedFor) {
                    // return detail for this availability
                    
                    return [MITLibrariesHoldingLibraryHeaderCopyInfoCell heightForItem:availability tableViewWidth:self.tableView.bounds.size.width];
                }
                totalRowsAccountedFor++;
            }
            
            if (adjustedRow == totalRowsAccountedFor) {
                // return view all button cell for this availability info
                return 44;
            }
            totalRowsAccountedFor++; // Account for "View all" cell
        }
    }
    
    return 0;
}

@end
