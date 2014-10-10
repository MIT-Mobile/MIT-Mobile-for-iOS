#import "MITLibrariesYourAccountItemDetailViewController.h"
#import "MITLibrariesItemDetailLineCell.h"
#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesMITLoanItem.h"
#import "MITLibrariesMITFineItem.h"
#import "MITLibrariesMITHoldItem.h"

static NSString * const kMITLibrariesItemLoanFineCellIdentifier = @"kMITLibrariesItemLoanFineCellIdentifier";
static NSString * const kMITLibrariesItemHoldCellIdentifier = @"kMITLibrariesItemHoldCellIdentifier";
static NSString * const kItemDetailLineCellIdentifier = @"kItemDetailLineCellIdentifier";

static NSString * const kItemLineTitleKey = @"kItemLineTitleKey";
static NSString * const kItemLineDetailKey = @"kItemLineDetailKey";

typedef NS_ENUM(NSInteger, MITLibrariesItemType) {
    MITLibrariesItemTypeLoan,
    MITLibrariesItemTypeFine,
    MITLibrariesItemTypeHold
};

@interface MITLibrariesYourAccountItemDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *itemDetailLines;
@property (nonatomic, assign) MITLibrariesItemType itemType;

@end

@implementation MITLibrariesYourAccountItemDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self registerCells];
}

- (void)registerCells
{
    UINib *loanFineItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemLoanFineCell class]) bundle:nil];
    [self.tableView registerNib:loanFineItemCellNib forCellReuseIdentifier:kMITLibrariesItemLoanFineCellIdentifier];
    
    UINib *holdItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemHoldCell class]) bundle:nil];
    [self.tableView registerNib:holdItemCellNib forCellReuseIdentifier:kMITLibrariesItemHoldCellIdentifier];
    
    UINib *librariesItemDetailCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemDetailLineCell class]) bundle:nil];
    [self.tableView registerNib:librariesItemDetailCellNib forCellReuseIdentifier:kItemDetailLineCellIdentifier];
}

- (void)recreateItemDetailLines
{
    NSMutableArray *newItemDetailLines = [NSMutableArray arrayWithCapacity:3];
    
    if (self.item.material.length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"Format",
                                        kItemLineDetailKey: self.item.material}];
    }
    
    if (self.item.imprint.length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"Publisher",
                                        kItemLineDetailKey: self.item.imprint}];
    }
    
    if (self.item.isbn.length > 0) {
        [newItemDetailLines addObject:@{kItemLineTitleKey: @"ISBN",
                                        kItemLineDetailKey: self.item.isbn}];
    }
    
    self.itemDetailLines = [NSArray arrayWithArray:newItemDetailLines];
}

- (void)setItem:(MITLibrariesMITItem *)item
{
    _item = item;
    
    if ([item isKindOfClass:[MITLibrariesMITLoanItem class]]) {
        self.itemType = MITLibrariesItemTypeLoan;
    } else if ([item isKindOfClass:[MITLibrariesMITFineItem class]]) {
        self.itemType = MITLibrariesItemTypeFine;
    } else if ([item isKindOfClass:[MITLibrariesMITHoldItem class]]) {
        self.itemType = MITLibrariesItemTypeHold;
    }
    
    [self recreateItemDetailLines];
    [self.tableView reloadData];
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1 + self.itemDetailLines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        switch (self.itemType) {
            case MITLibrariesItemTypeLoan:
            case MITLibrariesItemTypeFine: {
                MITLibrariesItemLoanFineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemLoanFineCellIdentifier];
                [cell setContent:self.item];
                return cell;
            }
            case MITLibrariesItemTypeHold: {
                MITLibrariesItemHoldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLibrariesItemHoldCellIdentifier];
                [cell setContent:self.item];
                return cell;
            }
        }
    } else {
        MITLibrariesItemDetailLineCell *detailLineCell = [self.tableView dequeueReusableCellWithIdentifier:kItemDetailLineCellIdentifier];
        NSDictionary *itemLineDictionary = self.itemDetailLines[indexPath.row - 1];
        detailLineCell.lineTitleLabel.text = [itemLineDictionary objectForKey:kItemLineTitleKey];
        detailLineCell.lineDetailLabel.text = [itemLineDictionary objectForKey:kItemLineDetailKey];
        return detailLineCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        switch (self.itemType) {
            case MITLibrariesItemTypeLoan:
            case MITLibrariesItemTypeFine: {
                return [MITLibrariesItemLoanFineCell heightForContent:self.item tableViewWidth:self.tableView.bounds.size.width];
            }
            case MITLibrariesItemTypeHold: {
                return [MITLibrariesItemHoldCell heightForContent:self.item tableViewWidth:self.tableView.bounds.size.width];
            }
        }
    } else {
        NSDictionary *itemLineDictionary = self.itemDetailLines[indexPath.row - 1];
        return [MITLibrariesItemDetailLineCell heightForTitle:[itemLineDictionary objectForKey:kItemLineTitleKey] detail:[itemLineDictionary objectForKey:kItemLineDetailKey] tableViewWidth:self.tableView.bounds.size.width];
    }
}

@end
