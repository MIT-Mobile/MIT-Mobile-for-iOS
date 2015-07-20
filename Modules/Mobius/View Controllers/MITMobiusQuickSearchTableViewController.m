#import "MITMobiusQuickSearchTableViewController.h"
#import "UITableView+DynamicSizing.h"
#import "MITMobiusQuickSearchTableViewCell.h"
#import "MITMobiusResourceType.h"
#import "MITMobiusRoomSet.h"

static NSString * const MITMobiusQuickSearchTableViewCellIdentifier = @"MITMobiusQuickSearchTableViewCellIdentifier";

@interface MITMobiusQuickSearchTableViewController () <UITableViewDataSourceDynamicSizing>

@property (nonatomic, strong) NSArray *objects;

@end

@implementation MITMobiusQuickSearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView:self.tableView];
}

- (void)setupTableView:(UITableView *)tableView
{
    [tableView registerNib:[MITMobiusQuickSearchTableViewCell quickSearchCellNib] forDynamicCellReuseIdentifier:MITMobiusQuickSearchTableViewCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self downloadObjectsForQuickSearch];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)downloadObjectsForQuickSearch
{
    __weak MITMobiusQuickSearchTableViewController *weakSelf = self;
    
    [self.dataSource getObjectsForRoute:self.typeOfObjects completion:^(NSArray *objects, NSError *error) {
        MITMobiusQuickSearchTableViewController *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"Error: %@",error);
        }
        self.objects = [objects copy];
        
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    CGFloat cellHeight = [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    return cellHeight;
}

- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0) {
        return MITMobiusQuickSearchTableViewCellIdentifier;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(applyQuickParams:)]) {
        [self.delegate applyQuickParams:self.objects[indexPath.row]];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if (reuseIdentifier != MITMobiusQuickSearchTableViewCellIdentifier) {
        return;
    }
    if (self.typeOfObjects == MITMobiusQuickSearchRoomSet) {
        if ([self.objects[indexPath.row] isKindOfClass:[MITMobiusRoomSet class]]) {

            MITMobiusRoomSet *type = self.objects[indexPath.row];
            MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
            quickSearch.label.text = type.name;
        }
        
    } else if (self.typeOfObjects == MITMobiusQuickSearchResourceType) {
        if ([self.objects[indexPath.row] isKindOfClass:[MITMobiusResourceType class]]) {
            
            MITMobiusResourceType *type = self.objects[indexPath.row];
            MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
            quickSearch.label.text = type.type;
        }
    }
}

@end
