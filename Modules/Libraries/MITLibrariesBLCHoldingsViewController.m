#import "MITLibrariesBLCHoldingsViewController.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "UIKit+MITLibraries.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesSingleTitleLabelCell.h"
#import "MITLibrariesSingleSubtitleLabelCell.h"
#import "MITLibrariesWorldcatItem.h"

static NSString * const kInfoSubtextString = @"Items unavailable from MIT may be available from the Boston Library Consortium members listed below. Visit the WorldCat website to request an interlibrary loan.";

static NSInteger const kItemHeaderSection = 0;
static NSInteger const kHoldingLibrariesSection = 1;

static NSInteger const kItemHeaderSectionHeaderCellRow = 0;
static NSInteger const kItemHeaderSectionSubtextCellRow = 1;
static NSInteger const kItemHeaderSectionWorldcatLinkCellRow = 2;

static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kInfoSubheaderCellIdentifier = @"kInfoSubheaderCellIdentifier";
static NSString * const kWorldcatLinkCellIdentifier = @"kWorldcatLinkCellIdentifier";
static NSString * const kHoldingLibraryCellIdentifier = @"kHoldingLibraryCellIdentifier";

@interface MITLibrariesBLCHoldingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation MITLibrariesBLCHoldingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"BLC Holdings";
    [self registerCells];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerCells
{
    UINib *itemHeaderNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.tableView registerNib:itemHeaderNib forCellReuseIdentifier:kItemHeaderCellIdentifier];
    
    UINib *subtitleCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesSingleSubtitleLabelCell class]) bundle:nil];
    [self.tableView registerNib:subtitleCellNib forCellReuseIdentifier:kInfoSubheaderCellIdentifier];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kWorldcatLinkCellIdentifier];
    
    UINib *holdingLibraryCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesSingleTitleLabelCell class]) bundle:nil];
    [self.tableView registerNib:holdingLibraryCellNib forCellReuseIdentifier:kHoldingLibraryCellIdentifier];
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kItemHeaderSection: {
            return 3;
        }
        case kHoldingLibrariesSection: {
            return self.holdingLibraryNames.count;
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kItemHeaderSection: {
            switch (indexPath.row) {
                case kItemHeaderSectionHeaderCellRow: {
                    MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
                    [itemHeaderCell setContent:self.worldcatItem];
                    [itemHeaderCell setShowsSeparator:NO];
                    return itemHeaderCell;
                }
                case kItemHeaderSectionSubtextCellRow: {
                    MITLibrariesSingleSubtitleLabelCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kInfoSubheaderCellIdentifier];
                    [cell setContent:kInfoSubtextString];
                    cell.backgroundColor = [UIColor clearColor];
                    cell.contentView.backgroundColor = [UIColor clearColor];
                    return cell;
                }
                case kItemHeaderSectionWorldcatLinkCellRow: {
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kWorldcatLinkCellIdentifier];
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.text = @"Worldcat Website";
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                    return cell;
                }
                default: {
                    return [UITableViewCell new];
                }
            }
        }
        case kHoldingLibrariesSection: {
            MITLibrariesSingleTitleLabelCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kHoldingLibraryCellIdentifier];
            
            [cell setContent:self.holdingLibraryNames[indexPath.row]];
            
            return cell;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kItemHeaderSection: {
            switch (indexPath.row) {
                case kItemHeaderSectionHeaderCellRow: {
                    return [MITLibrariesWorldcatItemCell heightForContent:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
                }
                case kItemHeaderSectionSubtextCellRow: {
                    return [MITLibrariesSingleSubtitleLabelCell heightForContent:kInfoSubtextString tableViewWidth:self.tableView.bounds.size.width];
                }
                case kItemHeaderSectionWorldcatLinkCellRow: {
                    return 44;
                }
                default: {
                    return 0;
                }
            }
        }
        case kHoldingLibrariesSection: {
            return [MITLibrariesSingleTitleLabelCell heightForContent:self.holdingLibraryNames[indexPath.row] tableViewWidth:self.tableView.bounds.size.width];
        }
        default: {
            return 0;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kItemHeaderSection: {
            return nil;
        }
        case kHoldingLibrariesSection: {
            return @"Owned By";
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kItemHeaderSection) {
        return 0.0001f;
    } else {
        return 35;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == kItemHeaderSection && indexPath.row == kItemHeaderSectionWorldcatLinkCellRow) {
        NSURL *linkURL = [NSURL URLWithString:self.worldcatItem.worldCatUrl];
        
        if ([[UIApplication sharedApplication] canOpenURL:linkURL]) {
            [[UIApplication sharedApplication] openURL:linkURL];
        }
    }
}

@end
