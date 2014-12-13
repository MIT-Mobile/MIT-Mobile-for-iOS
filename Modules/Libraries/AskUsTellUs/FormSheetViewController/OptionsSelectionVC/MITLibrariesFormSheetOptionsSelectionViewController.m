#import "MITLibrariesFormSheetOptionsSelectionViewController.h"
#import "MITLibrariesFormSheetElement.h"
#import "MITLibrariesFormSheetElementAvailableOption.h"

static NSString * const MITLibrariesFormSheetOptionsSelectionViewControllerCellIdentifier = @"MITLibrariesFormSheetOptionsSelectionViewControllerCellIdentifier";

@interface MITLibrariesFormSheetOptionsSelectionViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation MITLibrariesFormSheetOptionsSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

#pragma mark - Setup

- (void)setup
{
    [self setupTableView];
}

- (void)setupTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITLibrariesFormSheetOptionsSelectionViewControllerCellIdentifier];
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.element.availableOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesFormSheetOptionsSelectionViewControllerCellIdentifier forIndexPath:indexPath];
    MITLibrariesFormSheetElementAvailableOption *option = self.element.availableOptions[indexPath.row];
    if ([option.value isEqual:self.element.value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@", option.value];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MITLibrariesFormSheetElementAvailableOption *option = self.element.availableOptions[indexPath.row];
    self.element.value = option.value;
    [self.tableView reloadData];
}

@end
