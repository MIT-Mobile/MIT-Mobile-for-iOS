#import "MITNewsCategoryListViewController.h"
#import "MITNewsiPadViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStory.h"
#import "MITNewsConstants.h"
#import "MITNewsSearchController.h"

static NSString *errorMessage = @"Failed";

@interface MITNewsCategoryListViewController ()

@end

@implementation MITNewsCategoryListViewController {
    BOOL _storyUpdateInProgress;
    BOOL _storyUpdateFailed;
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

- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectStoryAtIndex:forCategoryInSection:)]) {
        [self.delegate viewController:self didSelectStoryAtIndex:indexPath.row forCategoryInSection:indexPath.section];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // May want to just use numberOfItemsInCategoryAtIndex: here and let the data source
    // figure out how many stories it wants to meter out to us
    if([self.dataSource canLoadMoreItemsForCategoryInSection:section]) {
        return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section] + 1;
    }
    return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section];
}

- (NSString*)titleForCategoryInSection:(NSUInteger)section
{
    return nil;
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.dataSource respondsToSelector:@selector(viewController:storyAtIndex:forCategoryInSection:)]) {
        return [self.dataSource viewController:self storyAtIndex:indexPath.row forCategoryInSection:0];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    if ([identifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (!_storyUpdateInProgress) {
            [self getMoreStoriesForSection:indexPath.section];
        }
    } else {
        MITNewsStory *story = [self storyAtIndexPath:indexPath];
        if (story) {
            [self didSelectStoryAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];

    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    if (identifier == MITNewsLoadMoreCellIdentifier && _storyUpdateFailed) {
        cell.textLabel.text = errorMessage;
    } else if (identifier == MITNewsLoadMoreCellIdentifier && _storyUpdateInProgress) {
        cell.textLabel.text = @"Loading More...";
    } else if (identifier == MITNewsLoadMoreCellIdentifier) {
        cell.textLabel.text = @"Load More...";
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
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            
            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                if (newsStory.coverImage) {
                    identifier = MITNewsStoryExternalCellIdentifier;
                } else {
                    identifier = MITNewsStoryExternalNoImageCellIdentifier;
                }
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
        
        return identifier;
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
        return 75; // Fixed height for the load more cells
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    }
}

- (void)getMoreStoriesForSection:(NSInteger *)section
{
    if([self.dataSource canLoadMoreItemsForCategoryInSection:section] && !_storyUpdateInProgress) {
        _storyUpdateInProgress = YES;
        [self.dataSource loadMoreItemsForCategoryInSection:section
                                                completion:^(NSError *error) {
                                                    _storyUpdateInProgress = FALSE;
                                                    if (error) {
                                                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                                                        errorMessage = error.localizedDescription;
                                                        _storyUpdateFailed = TRUE;
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                            [NSTimer scheduledTimerWithTimeInterval:2
                                                                                             target:self
                                                                                           selector:@selector(clearFailAfterTwoSeconds)
                                                                                           userInfo:nil
                                                                                            repeats:NO];
                                                        }];
                                                    } else {
                                                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            [self.tableView reloadData];
                                                        }];
                                                    }
                                                }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    _storyUpdateFailed = FALSE;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:0] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

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
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
