#import "MITDrawerViewController.h"
#import "MITSlidingViewController.h"
#import "MITModuleItem.h"

static NSString* const MITDrawerReuseIdentifierItemCell = @"ModuleItemCell";
static NSUInteger const MITModuleSectionIndex = 0;

@interface MITDrawerViewController ()
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

#pragma mark Properties
- (void)setModuleItems:(NSArray *)moduleItems
{
    [self setModuleItems:moduleItems animated:NO];
}

- (void)setModuleItems:(NSArray *)moduleItems animated:(BOOL)animated
{
    if (![_moduleItems isEqualToArray:moduleItems]) {
        
        [self willSetModuleItems:moduleItems animated:animated];
        
        _moduleItems = [moduleItems copy];
        
        [self didSetModuleItems:animated];
    }
}

- (void)willSetModuleItems:(NSArray*)newModuleItems animated:(BOOL)animated
{
    NSArray *oldModuleItems = _moduleItems;
    
    NSMutableSet *deletedModuleItems = [NSMutableSet setWithArray:oldModuleItems];
    [deletedModuleItems minusSet:[NSSet setWithArray:newModuleItems]];
    
    NSMutableArray *deletedIndexPaths = [[NSMutableArray alloc] init];
    [deletedModuleItems enumerateObjectsUsingBlock:^(MITModuleItem *moduleItem, BOOL *stop) {
        NSIndexPath *indexPath = [self _indexPathForModuleItem:moduleItem withModuleItems:oldModuleItems];
        [deletedIndexPaths addObject:indexPath];
    }];
    
    NSMutableSet *insertedModuleItems = [NSMutableSet setWithArray:newModuleItems];
    [insertedModuleItems minusSet:[NSSet setWithArray:oldModuleItems]];
    
    NSMutableArray *insertedIndexPaths = [[NSMutableArray alloc] init];
    [insertedModuleItems enumerateObjectsUsingBlock:^(MITModuleItem *moduleItem, BOOL *stop) {
        NSIndexPath *indexPath = [self _indexPathForModuleItem:moduleItem withModuleItems:oldModuleItems];
        [insertedIndexPaths addObject:indexPath];
    }];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didSetModuleItems:(BOOL)animated
{
    [self.tableView endUpdates];
}

- (void)setSelectedModuleItems:(MITModuleItem*)selectedModuleItem
{
    [self setSelectedModuleItem:selectedModuleItem animated:NO];
}

- (void)setSelectedModuleItem:(MITModuleItem*)selectedModuleItem animated:(BOOL)animated
{
    if (![_selectedModuleItem isEqual:selectedModuleItem]) {
        [self willSetSelectedModuleItem:selectedModuleItem animated:animated];
        
        _selectedModuleItem = selectedModuleItem;
        
        [self didSetSelectedModuleItem:animated];
    }
}

- (void)willSetSelectedModuleItem:(MITModuleItem*)newSelectedModuleItem animated:(BOOL)animated
{
    NSIndexPath *oldSelectedIndexPath = [self _indexPathForModuleItem:_selectedModuleItem withModuleItems:_moduleItems];
    
    [self.tableView beginUpdates];
    [self.tableView deselectRowAtIndexPath:oldSelectedIndexPath animated:animated];
}

- (void)didSetSelectedModuleItem:(BOOL)animated
{
    NSIndexPath *newSelectedIndexPath = [self _indexPathForModuleItem:_selectedModuleItem withModuleItems:_moduleItems];
    
    if (newSelectedIndexPath) {
        [self.tableView selectRowAtIndexPath:newSelectedIndexPath animated:animated scrollPosition:UITableViewScrollPositionNone];
    }
    
    [self.tableView endUpdates];
}

#pragma mark Private
- (MITModuleItem*)_moduleItemForIndexPath:(NSIndexPath*)indexPath withModuleItems:(NSArray*)moduleItems
{
    if (indexPath.section == MITModuleSectionIndex) {
        return moduleItems[indexPath.row];
    } else {
        return nil;
    }
}

- (NSIndexPath*)_indexPathForModuleItem:(MITModuleItem*)moduleItem withModuleItems:(NSArray*)moduleItems
{
    NSUInteger index = [moduleItems indexOfObject:moduleItem];

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
    return [self.moduleItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITDrawerReuseIdentifierItemCell forIndexPath:indexPath];
    if ([cell isKindOfClass:[UITableViewCell class]]) {
        MITModuleItem *moduleItem = [self _moduleItemForIndexPath:indexPath withModuleItems:self.moduleItems];
        
        cell.imageView.image = moduleItem.image;
        cell.textLabel.text = moduleItem.title;

        if ([moduleItem isEqual:_selectedModuleItem]) {
            cell.contentView.backgroundColor = self.view.tintColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.contentView.backgroundColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    
    MITModuleItem *selectedModuleItem = [self _moduleItemForIndexPath:indexPath withModuleItems:_moduleItems];
    self.selectedModuleItem = selectedModuleItem;
    
    if ([self.delegate respondsToSelector:@selector(drawerViewController:didSelectModuleItem:)]) {
        [self.delegate drawerViewController:self didSelectModuleItem:selectedModuleItem];
    }
}

@end
