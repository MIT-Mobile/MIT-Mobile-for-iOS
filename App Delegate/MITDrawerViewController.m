#import "MITDrawerViewController.h"
#import "MITModule.h"
#import "MITSlidingViewController.h"
#import "MITGradientView.h"

static NSString* const MITDrawerReuseIdentifierItemCell = @"DrawerItemCellReuseIdentifier";
static NSUInteger const MITModuleSectionIndex = 0;

@interface MITDrawerViewController ()
@property(nonatomic,weak) IBOutlet UIView *logoContainer;
@property(nonatomic,weak) IBOutlet UIImageView *logoView;
@property(nonatomic,weak) IBOutlet UITableView *tableView;
@property(nonatomic,weak) IBOutlet MITGradientView *topGradientView;
@property(nonatomic,weak) IBOutlet MITGradientView *bottomGradientView;

@property (nonatomic,strong) NSIndexPath *selectedIndexPath;
@end

@implementation MITDrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.topGradientView.direction = CGRectMinYEdge;
    self.bottomGradientView.direction = CGRectMaxYEdge;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.topGradientView.frame), 0, CGRectGetHeight(self.bottomGradientView.frame) / 2.0, 0);
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Properties
- (void)setModules:(NSArray *)modules
{
    if (![_modules isEqualToArray:modules]) {
        _modules = [modules copy];
        [self.tableView reloadData];
    }
}

- (void)setSelectedModule:(MITModule *)module
{
    NSIndexPath *selectedIndexPath = [self _indexPathForModule:module];
    if (selectedIndexPath) {
        _selectedModule = module;
        self.selectedIndexPath = selectedIndexPath;
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    [self setSelectedIndexPath:selectedIndexPath animated:NO];
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath animated:(BOOL)animated
{
    if (![_selectedIndexPath isEqual:selectedIndexPath]) {
        NSIndexPath *previousIndexPath = _selectedIndexPath;
        _selectedIndexPath = selectedIndexPath;
    }
}

#pragma mark Private

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
    return [self.modules count];
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
#warning replace with +[NSIndexPath indexPathForIndexPath:]
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITDrawerReuseIdentifierItemCell forIndexPath:indexPath];

    if ([cell isKindOfClass:[UITableViewCell class]]) {
        MITModule *module = [self _moduleForIndexPath:indexPath];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.image = module.springboardIcon;
        cell.textLabel.text = module.shortName;

        if ([self.selectedIndexPath isEqual:indexPath]) {
            cell.selected = YES;
            cell.contentView.backgroundColor = self.view.tintColor;
        } else {
            cell.selected = NO;
            cell.contentView.backgroundColor = [UIColor clearColor];
        }
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
#warning replace with +[NSIndexPath indexPathForIndexPath:]
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];

    if (![self.selectedIndexPath isEqual:indexPath]) {
        NSIndexPath *previousIndexPath = self.selectedIndexPath;
        self.selectedIndexPath = indexPath;
        [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath,previousIndexPath] withRowAnimation:UITableViewScrollPositionNone];
    }
    
    MITModule *module = [self _moduleForIndexPath:indexPath];
    [MIT_MobileAppDelegate applicationDelegate].rootViewController.visibleModule = module;
}

@end
