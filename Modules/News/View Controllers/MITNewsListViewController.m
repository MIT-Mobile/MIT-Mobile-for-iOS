#import "MITNewsListViewController.h"

#import <objc/runtime.h>
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsStoryViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsLoadMoreTableViewCell.h"
#import "MITDisclosureHeaderView.h"
#import "UIImageView+WebCache.h"

#import "MITNewsConstants.h"
#import "MITAdditions.h"
#import "UITableView+DynamicSizing.h"
#import "MITNewsViewController.h"
#import "MITNewsLoadMoreTableViewCell.h"

static NSUInteger MITNewsDefaultNumberOfFeaturedStories = 5;
static NSUInteger MITNewsViewControllerTableViewHeaderHeight = 8;

@interface MITNewsListViewController () <UITableViewDataSourceDynamicSizing>
@property (nonatomic, strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic, strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic, strong) NSMutableDictionary *storyHeightsDictionary;
@property (nonatomic) BOOL displayLoadingMoreMessage;

#pragma mark Story Data Source methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath;
@end

@implementation MITNewsListViewController


#pragma mark Dynamic Properties
- (NSMutableDictionary*)storyHeightsDictionary
{
    if (!_storyHeightsDictionary) {
        NSMutableDictionary *storyHeightsDictionary = [[NSMutableDictionary alloc] init];
        _storyHeightsDictionary = storyHeightsDictionary;
    }
    return _storyHeightsDictionary;
}


#pragma mark UI Element text attributes
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil managedObjectContext:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil managedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

#pragma mark Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.maximumNumberOfStoriesPerCategory = MITNewsDefaultNumberOfFeaturedStories;
    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];

    [self didLoadTableView:self.tableView];
}

- (void)didLoadTableView:(UITableView*)tableView
{
    tableView.dataSource = self;
    tableView.delegate = self;

    [tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:MITNewsCategoryHeaderIdentifier];

    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
    
    // adding an empty header to set the white margin for the first header section.
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), MITNewsViewControllerTableViewHeaderHeight)];
    [tableView setTableHeaderView:tableHeaderView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark Notifications
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark View Orientation
- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Property Setters & Getters
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }

    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark - Responding to UI events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    NSIndexPath *categoryIndexPath = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];
    if (categoryIndexPath) {
        [self didSelectCategoryInSection:[categoryIndexPath indexAtPosition:0]];
    }
}

- (MITNewsStory*)selectedStory
{
    UITableView *tableView = self.tableView;
    NSIndexPath* selectedIndexPath = [tableView indexPathForSelectedRow];

    return [self storyAtIndexPath:selectedIndexPath];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString* const titleForSection = [self titleForCategoryInSection:section];

    if (!titleForSection) {
        return 0;
    } else {
        return 44.;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* const headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MITNewsCategoryHeaderIdentifier];
    NSString* const titleForSection = [self titleForCategoryInSection:section];
    const BOOL isFeaturedSection = [self isFeaturedCategoryInSection:section];

    if ([headerView isKindOfClass:[MITDisclosureHeaderView class]]) {
        MITDisclosureHeaderView *disclosureHeaderView = (MITDisclosureHeaderView*)headerView;
        disclosureHeaderView.titleLabel.text = titleForSection;
        disclosureHeaderView.highlightingView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];

        if (isFeaturedSection) {
            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:disclosureHeaderView];
            if (recognizer) {
                [disclosureHeaderView removeGestureRecognizer:recognizer];
                [self.categoriesByGestureRecognizer removeObjectForKey:recognizer];
                [self.gestureRecognizersByView removeObjectForKey:headerView];
            }

            disclosureHeaderView.accessoryView.hidden = YES;
        } else {
            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
            if (!recognizer) {
                recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
                [headerView addGestureRecognizer:recognizer];
            }

            // Keep track of the gesture recognizers we create so we can remove
            // them later
            [self.gestureRecognizersByView setObject:recognizer forKey:headerView];

            NSIndexPath *categoryIndexPath = [NSIndexPath indexPathWithIndex:section];
            [self.categoriesByGestureRecognizer setObject:categoryIndexPath forKey:recognizer];

            disclosureHeaderView.accessoryView.hidden = NO;
        }
    }

    return headerView;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        [storyCell.storyImageView sd_cancelCurrentImageLoad];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return MITNewsLoadMoreTableViewCellHeight;
    }
    CGFloat cellHeight = [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    [self setCachedHeight:cellHeight forRowAtIndexPath:indexPath];
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return MITNewsLoadMoreTableViewCellHeight;
    } else if ([self cachedHeightForRowAtIndexPath:indexPath]) {
        return [self cachedHeightForRowAtIndexPath:indexPath];
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)cachedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    if (story && self.storyHeightsDictionary[story.identifier]) {
        return [self.storyHeightsDictionary[story.identifier] floatValue];
    }
    return UITableViewAutomaticDimension;
}

- (void)setCachedHeight:(CGFloat)height forRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    if (story) {
        self.storyHeightsDictionary[story.identifier] = @(height);
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block BOOL isExternalStory = NO;
    __block NSURL *externalURL = nil;
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    
    if ([story.type isEqualToString:MITNewsStoryExternalType]) {
        isExternalStory = YES;
        externalURL = story.sourceURL;
    }

    return (!isExternalStory || [[UIApplication sharedApplication] canOpenURL:externalURL]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    if ([identifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        [self getMoreStoriesForSection:indexPath.section];
    } else {
        [self didSelectStoryAtIndexPath:indexPath];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self numberOfCategories];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // May want to just use numberOfItemsInCategoryAtIndex: here and let the data source
    // figure out how many stories it wants to meter out to us
    
    if (self.isACategoryView) {
        NSInteger numberOfRows = [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section];
        if([self.dataSource canLoadMoreItemsForCategoryInSection:section]) {
            return numberOfRows + 1;
        }
        return numberOfRows;
    }
    return MIN(self.maximumNumberOfStoriesPerCategory,[self numberOfStoriesForCategoryInSection:section]);
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(identifier,@"[%@] missing cell reuse identifier in %@",self,NSStringFromSelector(_cmd));
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if ([cell isKindOfClass:[MITNewsLoadMoreTableViewCell class]]) {
            MITNewsLoadMoreTableViewCell *loadMoreCell = (MITNewsLoadMoreTableViewCell*)cell;

            if (_errorMessage) {
                loadMoreCell.textLabel.text = _errorMessage;
                _errorMessage = nil;
                loadMoreCell.loadingIndicator.hidden = YES;
                [loadMoreCell.loadingIndicator stopAnimating];
                _displayLoadingMoreMessage = YES;
                
            } else if (_storyUpdateInProgress) {
                loadMoreCell.textLabel.text = @"Loading More...";
                loadMoreCell.loadingIndicator.hidden = NO;
                [loadMoreCell.loadingIndicator startAnimating];
                _displayLoadingMoreMessage = NO;
                
            } else if (_displayLoadingMoreMessage || _storyRefreshInProgress) {
                loadMoreCell.textLabel.text = @"Load More...";
                loadMoreCell.loadingIndicator.hidden = YES;
                [loadMoreCell.loadingIndicator stopAnimating];
                
            } else {
                loadMoreCell.textLabel.text = @"Loading More...";
                loadMoreCell.loadingIndicator.hidden = NO;
                [loadMoreCell.loadingIndicator startAnimating];
                _displayLoadingMoreMessage = NO;
            }
            
            CGFloat separatorPadding = (CGRectGetWidth(self.tableView.bounds) - MIN(CGRectGetWidth(self.tableView.bounds),648.)) / 2.;
            CGFloat rightPadding = loadMoreCell.textLabel.frame.origin.x;
            cell.separatorInset = UIEdgeInsetsMake(0, separatorPadding + rightPadding, 0, separatorPadding);
            
        } else {
            DDLogWarn(@"cell at %@ with identifier %@ expected a cell of type %@, got %@",indexPath,cell.reuseIdentifier,NSStringFromClass([MITNewsLoadMoreTableViewCell class]),NSStringFromClass([cell class]));
            
            return cell;
        }
    }
    
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell *)cell;
        CGFloat separatorPadding = (CGRectGetWidth(self.tableView.bounds) - MIN(CGRectGetWidth(self.tableView.bounds),648.)) / 2.;
        CGFloat rightPadding = 0;
        if (storyCell.titleLabel) {
           rightPadding = storyCell.titleLabel.frame.origin.x;
        } else if(storyCell.dekLabel) {
            rightPadding = storyCell.dekLabel.frame.origin.x;
        }
        cell.separatorInset = UIEdgeInsetsMake(0, separatorPadding + rightPadding, 0, separatorPadding);
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath

{
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if ([cell isKindOfClass:[MITNewsLoadMoreTableViewCell class]]) {
            
            if (!_errorMessage && !_storyUpdateInProgress && !_displayLoadingMoreMessage && !_storyRefreshInProgress) {
                [self getMoreStoriesForSection:indexPath.section];
            }
            
        } else {
            DDLogWarn(@"cell at %@ with identifier %@ expected a cell of type %@, got %@",indexPath,cell.reuseIdentifier,NSStringFromClass([MITNewsLoadMoreTableViewCell class]),NSStringFromClass([cell class]));
        }
    }
}

#pragma mark UITableViewDataSourceDynamicSizing
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        storyCell.story = [self storyAtIndexPath:indexPath];
    }
}

#pragma mark UITableView Data Source/Delegate Helper Methods
- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];

    if (story) {
        __block NSString *identifier = nil;
        if ([story.type isEqualToString:MITNewsStoryExternalType]) {
            if (story.coverImage) {
                identifier = MITNewsStoryExternalCellIdentifier;
            } else {
                identifier = MITNewsStoryExternalNoImageCellIdentifier;
            }
        } else if ([story.dek length])  {
            identifier = MITNewsStoryCellIdentifier;
        } else {
            identifier = MITNewsStoryNoDekCellIdentifier;
        }

        return identifier;
    } else {
        if ([self numberOfStoriesForCategoryInSection:indexPath.section] && self.isACategoryView == YES) {
            return MITNewsLoadMoreCellIdentifier;
        }
        return nil;
    }
}

#pragma mark MITNewsStory delegate/datasource passthru methods
- (NSUInteger)numberOfCategories
{
    if ([self.dataSource respondsToSelector:@selector(numberOfCategoriesInViewController:)]) {
        return [self.dataSource numberOfCategoriesInViewController:self];
    } else {
        return 0;
    }
}

- (BOOL)isFeaturedCategoryInSection:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:isFeaturedCategoryInSection:)]) {
        return [self.dataSource viewController:self isFeaturedCategoryInSection:index];
    } else {
        return NO;
    }
}

- (NSString*)titleForCategoryInSection:(NSUInteger)section
{
    if ([self.dataSource respondsToSelector:@selector(viewController:titleForCategoryInSection:)]) {
        return [self.dataSource viewController:self titleForCategoryInSection:section];
    } else {
        return nil;
    }
}

- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:numberOfStoriesForCategoryInSection:)]) {
        return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:index];
    } else {
        return 0;
    }
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.dataSource respondsToSelector:@selector(viewController:storyAtIndex:forCategoryInSection:)]) {
        return [self.dataSource viewController:self storyAtIndex:indexPath.row forCategoryInSection:indexPath.section];
    } else {
        return nil;
    }
}

- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectStoryAtIndex:forCategoryInSection:)]) {
        [self.delegate viewController:self didSelectStoryAtIndex:indexPath.row forCategoryInSection:indexPath.section];
    }
}

- (void)didSelectCategoryInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectCategoryInSection:)]) {
        [self.delegate viewController:self didSelectCategoryInSection:section];
    }
}

- (void)getMoreStoriesForSection:(NSInteger)section
{
    [self.delegate getMoreStoriesForSection:section completion:nil];
}

@end
