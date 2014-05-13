#import "MITLauncherListViewController.h"
#import "MITLauncher.h"
#import "MITLauncherListViewCell.h"

static NSString* const MITLauncherModuleListCellIdentifier = @"LauncherModuleListCell";
static NSString* const MITLauncherModuleListNibName = @"LauncherModuleListCell";

@interface MITLauncherListViewController ()

@end

@implementation MITLauncherListViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:MITLauncherModuleListNibName bundle:nil] forCellReuseIdentifier:MITLauncherModuleListCellIdentifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInLauncher:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITLauncherModuleListCellIdentifier forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[MITLauncherListViewCell class]]) {
        MITLauncherListViewCell *launcherCell = (MITLauncherListViewCell*)cell;
        
        MITModule *module = [self.dataSource launcher:self moduleAtIndexPath:indexPath];
        launcherCell.module = module;
        launcherCell.shouldUseShortModuleNames = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate launcher:self didSelectModuleAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
