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
    [self retrieveBlah];
}

- (void)retrieveBlah
{
    __weak MITMobiusQuickSearchTableViewController *weakSelf = self;
    
    MITMobiusRequestType *type = nil;
    
    if (self.typeOfObjects == MITMobiusShopsAndLabs) {
        type = MITMobiusRequestTypeResourceRoomset;
    } else if (self.typeOfObjects == MITMobiusMachineTypes) {
        type = MITMobiusRequestTypeResourceType;
    }
    
    [self.dataSource getObjectsForRoute:type completion:^(NSArray *objects, NSError *error) {
        MITMobiusQuickSearchTableViewController *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"Error: %@",error);
        }
        self.objects = [objects copy];
        
        [self.tableView reloadData];
        
        // [self.dataSource resourcesWithQuery:queryString completion:^(MITMobiusResourceDataSource *dataSource, NSError *error) {
        //    MITMobiusRootPhoneViewController *blockSelf = weakSelf;
        
        
        
        /* if (!blockSelf) {
         return;
         } else if (error) {
         DDLogWarn(@"Error: %@",error);
         
         if (block) {
         [[NSOperationQueue mainQueue] addOperationWithBlock:block];
         }
         } else {
         [blockSelf.managedObjectContext performBlockAndWait:^{
         [blockSelf.managedObjectContext reset];
         blockSelf.rooms = nil;
         
         if (block) {
         [[NSOperationQueue mainQueue] addOperationWithBlock:block];
         [blockSelf.recentSearchViewController addRecentSearchTerm:queryString];
         }
         }];
         }
         }];*/
        //    } else {
        //        self.contentContainerView.hidden = YES;
        //        self.quickLookupTableView.hidden = NO;
        //   }
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

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if (reuseIdentifier != MITMobiusQuickSearchTableViewCellIdentifier) {
        return;
    }
    if (self.typeOfObjects == MITMobiusShopsAndLabs) {
        
        MITMobiusRoomSet *type = self.objects[indexPath.row];
        
        MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
        quickSearch.label.text = type.name;
        
    } else if (self.typeOfObjects == MITMobiusMachineTypes) {
        
        MITMobiusResourceType *type = self.objects[indexPath.row];
        
        MITMobiusQuickSearchTableViewCell *quickSearch = (MITMobiusQuickSearchTableViewCell*)cell;
        quickSearch.label.text = type.type;
    }
}
@end
