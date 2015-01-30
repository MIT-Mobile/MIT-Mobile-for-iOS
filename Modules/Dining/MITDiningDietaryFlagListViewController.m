#import "MITDiningDietaryFlagListViewController.h"
#import "MITDiningDietaryFlagListCell.h"

static NSString *const kMITDiningDietaryFlagListCellIdentifier = @"kMITDiningDietaryFlagListCellIdentifier";
static NSString *const kMITDiningDietaryFlagListCellNibName = @"MITDiningDietaryFlagListCell";

@interface MITDiningDietaryFlagListViewController ()

@end

@implementation MITDiningDietaryFlagListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:kMITDiningDietaryFlagListCellNibName bundle:nil] forCellReuseIdentifier:kMITDiningDietaryFlagListCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
}

- (void)setFlags:(NSArray *)flags
{
    if ([flags isEqualToArray:_flags]) {
        return;
    }
    
    _flags = flags;
    [self.tableView reloadData];
}

#pragma mark - Public Methods

- (CGSize)targetTableViewSize
{
    CGFloat tableHeight= 0.0;
    CGFloat maxCellWidth = 0.0;
    
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++) {
        for (NSInteger row = 0; row < [self tableView:self.tableView numberOfRowsInSection:section]; row++) {
            tableHeight += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            MITDiningDietaryFlagListCell *cell = (MITDiningDietaryFlagListCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if ([cell targetWidth] > maxCellWidth) {
                maxCellWidth = [cell targetWidth];
            }
        }
    }
    
    return CGSizeMake(maxCellWidth, tableHeight);
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.flags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningDietaryFlagListCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITDiningDietaryFlagListCellIdentifier];
    
    [cell setFlag:self.flags[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 36.0;
}

@end
