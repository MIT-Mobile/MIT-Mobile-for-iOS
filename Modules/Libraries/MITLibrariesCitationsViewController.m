#import "MITLibrariesCitationsViewController.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesCitationCell.h"

static NSInteger const kItemHeaderSection = 0;

static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kCitationCellIdentifier = @"kCitationCellIdentifier";

@interface MITLibrariesCitationsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *citationCellHeights;
@property (nonatomic, assign) CGFloat previousTableViewWidth;

@end

@implementation MITLibrariesCitationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Citations";
    self.tableView.delaysContentTouches = NO;
    self.previousTableViewWidth = self.tableView.bounds.size.width;
    
    [self registerCells];
    
    if (self.worldcatItem) {
        [self refreshCitationCellHeights];
    }
}

- (void)registerCells
{
    UINib *librariesItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.tableView registerNib:librariesItemCellNib forCellReuseIdentifier:kItemHeaderCellIdentifier];
    
    UINib *citationCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesCitationCell class]) bundle:nil];
    [self.tableView registerNib:citationCellNib forCellReuseIdentifier:kCitationCellIdentifier];
}

- (void)setWorldcatItem:(MITLibrariesWorldcatItem *)worldcatItem
{
    if ([_worldcatItem isEqual:worldcatItem]) {
        return;
    }
    
    _worldcatItem = worldcatItem;
    
    if (self.tableView) {
        [self refreshCitationCellHeights];
    }
}

- (void)refreshCitationCellHeights
{
    // Load all the cell heights before showing, since they're all webviews and we'd rather not change the cell height on-screen like 5 times as the didLoad calls come in
    dispatch_group_t heightCalculationGroup = dispatch_group_create();
    NSMutableArray *newCitationCellHeights = [NSMutableArray arrayWithCapacity:self.worldcatItem.citations.count];
    for (NSInteger i = 0; i < self.worldcatItem.citations.count; i++) {
        [newCitationCellHeights addObject:[NSNumber numberWithFloat:44.0]];
    }
    
    for (MITLibrariesCitation *citation in self.worldcatItem.citations) {
        dispatch_group_enter(heightCalculationGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [MITLibrariesCitationCell heightWithCitation:citation tableWidth:self.tableView.bounds.size.width completion:^(CGFloat height) {
                [newCitationCellHeights replaceObjectAtIndex:[self.worldcatItem.citations indexOfObject:citation] withObject:[NSNumber numberWithFloat:height]];
                dispatch_group_leave(heightCalculationGroup);
            }];
        });
    }

    dispatch_group_notify(heightCalculationGroup, dispatch_get_main_queue(), ^{
        self.citationCellHeights = [NSArray arrayWithArray:newCitationCellHeights];
        [self.tableView reloadData];
    });
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.tableView.bounds.size.width != self.previousTableViewWidth) {
        self.previousTableViewWidth = self.tableView.bounds.size.width;
        [self refreshCitationCellHeights];
    }
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + self.worldcatItem.citations.count;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kItemHeaderSection) {
        MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
        [itemHeaderCell setContent:self.worldcatItem];
        return itemHeaderCell;
    } else {
        MITLibrariesCitationCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCitationCellIdentifier];
        [cell setCitation:self.worldcatItem.citations[indexPath.section - 1]];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kItemHeaderSection) {
        return [MITLibrariesWorldcatItemCell heightForContent:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
    } else {
        if (self.citationCellHeights.count > indexPath.row) {
            return [self.citationCellHeights[indexPath.section - 1] floatValue];
        } else {
            return 0;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kItemHeaderSection) {
        return nil;
    } else {
        MITLibrariesCitation *citation = self.worldcatItem.citations[section - 1];
        return citation.name;
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

@end
