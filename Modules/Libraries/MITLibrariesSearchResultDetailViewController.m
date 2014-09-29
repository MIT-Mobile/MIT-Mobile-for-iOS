#import "MITLibrariesSearchResultDetailViewController.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesItemDetailLineCell.h"
#import "MITLibrariesHoldingLibraryCell.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesWebservices.h"

static NSString * const kDefaultCellIdentifier = @"kDefaultCellIdentifier";
static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kItemDetailLineCellIdentifier = @"kItemDetailLineCellIdentifier";
static NSString * const kHoldingLibraryCellIdentifier = @"kHoldingLibraryCellIdentifier";

static NSInteger const kBookInfoSection = 0;
static NSInteger const kCitationsSection = 1;
static NSInteger const kHoldingLibrariesSection = 2;
static NSInteger const kBLCHoldingsSection = 3;

static NSString * const kItemLineTitleKey = @"kItemLineTitleKey";
static NSString * const kItemLineDetailKey = @"kItemLineDetailKey";

@interface MITLibrariesSearchResultDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *itemDetailLines;

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
    
    UINib *librariesHoldingCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesHoldingLibraryCell class]) bundle:nil];
    [self.tableView registerNib:librariesHoldingCellNib forCellReuseIdentifier:kHoldingLibraryCellIdentifier];
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
            return 0;
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
        
    }
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
        
    }
}

@end
