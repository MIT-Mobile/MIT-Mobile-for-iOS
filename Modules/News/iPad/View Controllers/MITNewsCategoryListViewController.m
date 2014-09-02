#import "MITNewsCategoryListViewController.h"
#import "MITNewsiPadViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStory.h"
#import "MITNewsConstants.h"
#import "MITNewsSearchController.h"
#import "MITNewsLoadMoreTableViewCell.h"

@interface MITNewsCategoryListViewController()
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, strong) NSMutableDictionary *storyHeights;
@end

@implementation MITNewsCategoryListViewController {
    BOOL _storyUpdateInProgress;
}

#pragma mark Dynamic Properties
- (NSMutableDictionary*)storyHeights
{
    if (!_storyHeights) {
        NSMutableDictionary* storyHeights = [[NSMutableDictionary alloc] init];
        _storyHeights = storyHeights;
    }
    return _storyHeights;
}

#pragma mark MITNewsStory delegate/datasource passthru methods
- (NSUInteger)numberOfCategories
{
    if ([self.dataSource respondsToSelector:@selector(numberOfCategoriesInViewController:)]) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // May want to just use numberOfItemsInCategoryAtIndex: here and let the data source
    // figure out how many stories it wants to meter out to us

    NSInteger numberOfRows = [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section];
    NSInteger numberOfStoryHeights = [self.storyHeights count];
    if (numberOfStoryHeights > numberOfRows) {
        [self.storyHeights removeAllObjects];
    }
    if([self.dataSource canLoadMoreItemsForCategoryInSection:section]) {
        return numberOfRows + 1;
    }
    return numberOfRows;
}

- (NSString*)titleForCategoryInSection:(NSUInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    if ([identifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (!_storyUpdateInProgress) {
            [self getMoreStoriesForSection:indexPath.section];
        }
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if ([cell isKindOfClass:[MITNewsLoadMoreTableViewCell class]]) {
            [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
        
            if (self.errorMessage) {
                cell.textLabel.text = self.errorMessage;
            } else if (_storyUpdateInProgress) {
                cell.textLabel.text = @"Loading More...";
            } else {
                cell.textLabel.text = @"Load More...";
            }
        } else {
            DDLogWarn(@"cell at %@ with identifier %@ expected a cell of type %@, got %@",indexPath,cell.reuseIdentifier,NSStringFromClass([MITNewsLoadMoreTableViewCell class]),NSStringFromClass([cell class]));
            
            return cell;
        }
    }
    return cell;
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        storyCell.story = [self storyAtIndexPath:indexPath];
    } else if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (_storyUpdateInProgress) {
            if (!cell.accessoryView) {
                UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [view startAnimating];
                cell.accessoryView = view;
            }
        } else {
            cell.accessoryView = nil;
        }
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = nil;
    if ([self numberOfStoriesForCategoryInSection:indexPath.section] > indexPath.row) {
        story = [self storyAtIndexPath:indexPath];
    }
    if (story) {
        return [super reuseIdentifierForRowAtIndexPath:indexPath];
    } else if ([self numberOfStoriesForCategoryInSection:indexPath.section]) {
        return MITNewsLoadMoreCellIdentifier;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return MITNewsLoadMoreTableViewCellHeight;
    } else {
        CGFloat cellHeight = [super tableView:tableView heightForRowAtIndexPath:indexPath];
        
        CGFloat estimatedHeight = [self.storyHeights[indexPath] doubleValue];
        if (estimatedHeight != cellHeight) {
            [self setHeight:cellHeight forRowAtIndexPath:indexPath];
        }
        return cellHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return MITNewsLoadMoreTableViewCellHeight;
    } else if ([self heightForRowAtIndexPath:indexPath]) {
        return [self heightForRowAtIndexPath:indexPath];
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *convertedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    return [self.storyHeights[convertedIndexPath] doubleValue];
}

- (void)setHeight:(CGFloat)height forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSIndexPath *convertedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    self.storyHeights[convertedIndexPath] = @(height);
}

- (void)getMoreStoriesForSection:(NSInteger *)section
{
    if(!_storyUpdateInProgress && !self.errorMessage) {
        _storyUpdateInProgress = YES;
        [self reloadCellAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] inSection:0]];

        [self.delegate getMoreStoriesForSection:section completion:^(NSError * error) {
            _storyUpdateInProgress = FALSE;
            if (error) {
                if (error.code == -1009) {
                    self.errorMessage = @"No Internet Connection";
                } else {
                    self.errorMessage = @"Failed...";
                }
                if (self.navigationController.toolbarHidden) {
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [NSTimer scheduledTimerWithTimeInterval:2
                                                         target:self
                                                       selector:@selector(clearFailAfterTwoSeconds)
                                                       userInfo:nil
                                                        repeats:NO];
                    }];
                } else {
                    self.errorMessage = nil;
                }
                [self reloadCellAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] inSection:0]];
            }
        }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    self.errorMessage = nil;
    [self reloadCellAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:0] inSection:0]];
}

- (void)reloadCellAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

@end
