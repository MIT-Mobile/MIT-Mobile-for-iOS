#import "MITDrawerViewController.h"
#import "UIViewController+MITDrawerNavigation.h"
#import "MITModule.h"
#import "MITRootViewController.h"

static NSString* const MITDrawerReuseIdentifierItemCell = @"DrawerItemCellReuseIdentifier";
static NSUInteger const MITModuleSectionIndex = 0;

@interface MITDrawerViewController ()
@property(nonatomic,strong) IBOutlet UIView *topView;
@property(nonatomic,strong) IBOutlet UIImageView *logoView;
@property(nonatomic,strong) IBOutlet UITableView *tableView;
@property(nonatomic,strong) IBOutlet MITGradientView *gradientView;

@property (nonatomic,strong) NSIndexPath *selectedIndexPath;
@end

@implementation MITDrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MITModule*)_moduleForIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == MITModuleSectionIndex) {
        return self.modules[indexPath.row];
    } else {
        return nil;
    }
}

- (NSIndexPath*)_indexPathForModule:(MITModule*)module
{
    NSUInteger index = [self.modules indexOfObject:module];

    if (index == NSNotFound) {
        return nil;
    } else {
        return [NSIndexPath indexPathForRow:index inSection:MITModuleSectionIndex];
    }
}

#pragma mark - Delegation
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[MIT_MobileAppDelegate applicationDelegate].modules count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITDrawerReuseIdentifierItemCell forIndexPath:indexPath];

    if ([cell isKindOfClass:[UITableViewCell class]]) {
        MITRootViewController *slidingViewController = [[MIT_MobileAppDelegate applicationDelegate] rootViewController];
        MITModule *module = [self _moduleForIndexPath:indexPath];

        if (slidingViewController.selectedModule == module) {
            cell.imageView.image = module.springboardIcon;
            cell.contentView.backgroundColor = self.view.tintColor;
        } else {
            cell.imageView.image = module.springboardIcon;
            cell.contentView.backgroundColor = self.view.backgroundColor;
        }

        cell.textLabel.text = module.shortName;
    }

    return cell;
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITRootViewController *slidingViewController = [[MIT_MobileAppDelegate applicationDelegate] rootViewController];
    MITModule *selectedModule = slidingViewController.selectedModule;
    MITModule *module = [self _moduleForIndexPath:indexPath];
    if (slidingViewController.selectedModule == module) {
        return;
    } else {
        NSIndexPath *selectedIndexPath = [self _indexPathForModule:selectedModule];
        slidingViewController.selectedModule = selectedModule;
        [tableView reloadRowsAtIndexPaths:@[selectedIndexPath,indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
