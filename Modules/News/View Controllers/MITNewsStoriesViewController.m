#import "MITNewsStoriesViewController.h"
#import "MITNewsStoryCell.h"
#import "MITCoreData.h"

#import "MITAdditions.h"
#import "MITDisclosureHeaderView.h"

#import "MITNewsModelController.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsCategory.h"
#import "MITNewsStory.h"

#import "UIImageView+WebCache.h"

static NSString* const MITNewsStoryCellIdentifier = @"StoryCell";
static NSString* const MITNewsStoryCellNibName = @"NewsStoryTableCell";

static NSString* const MITNewsStoryNoDekCellIdentifier = @"StoryNoDekCell";
static NSString* const MITNewsStoryNoDekCellNibName = @"NewsStoryNoDekTableCell";

static NSString* const MITNewsStoryExternalType = @"news_clip";
static NSString* const MITNewsStoryExternalCellIdentifier = @"StoryExternalCell";
static NSString* const MITNewsStoryExternalCellNibName = @"NewsStoryExternalTableCell";

@interface MITNewsStoriesViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic) BOOL needsNavigationItemUpdate;
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *sizingCellsByIdentifier;

@property (nonatomic,strong) NSFetchedResultsController *featuredStoriesFetchedResultsController;
@property (nonatomic,strong) NSFetchedResultsController *categoriesFetchedResultsController;

@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSMutableArray *searchResults;

@property (nonatomic,readonly) MITNewsStory *selectedStory;

- (UITableViewHeaderFooterView*)createLoadMoreFooterView;
@end

@implementation MITNewsStoriesViewController
+ (NSDictionary*)updateItemTextAttributes
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:[UIFont smallSystemFontSize]],
             NSForegroundColorAttributeName: [UIColor blackColor]};
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

    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];

    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];
    self.sizingCellsByIdentifier = [NSMapTable strongToWeakObjectsMapTable];

    self.tableView.tableHeaderView = self.searchDisplayController.searchBar;

    CGPoint offset = self.tableView.contentOffset;
    offset.y = CGRectGetMaxY(self.searchDisplayController.searchBar.frame);
    self.tableView.contentOffset = offset;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __block NSString *title = @"Top Stories";
    
    if (_category) {
        [self.managedObjectContext performBlockAndWait:^{
            title = self.category.name;
        }];
    }
    
    self.title = title;

    [self performDataUpdate:^(NSError *error){
        [self.tableView reloadData];

        if (!error) {
            self.tableView.tableFooterView = [self createLoadMoreFooterView];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCategory:(MITNewsCategory *)category
{
    if (![_category isEqual:category]) {
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        
        if (category) {
            _category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[category objectID]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@",self.category];
        }
        
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                         [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
        self.fetchRequest = fetchRequest;
    }
}

#pragma mark - Managing states
#pragma mark Updating
- (void)setUpdating:(BOOL)updating
{
    [self setUpdating:updating animated:NO];
}

- (void)setUpdating:(BOOL)updating animated:(BOOL)animated
{
    if (_updating != updating) {
        if (updating) {
            [self willBeginUpdating:animated];
        }

        _updating = updating;
    }
}

- (void)willBeginUpdating:(BOOL)animated
{
    [self setUpdateText:@"Updating..." animated:animated];
}

- (void)setUpdateText:(NSString*)string animated:(BOOL)animated
{
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.attributedText = [[NSAttributedString alloc] initWithString:string attributes:[MITNewsStoriesViewController updateItemTextAttributes]];
    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];

    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark Navigation Item
- (void)updateNavigationItemIfNeeded
{
    if (self.needsNavigationItemUpdate) {
        UIScrollView *tableView = self.tableView;

        CGRect visibleRect = tableView.bounds;
        visibleRect.origin.x = tableView.contentOffset.x + tableView.contentInset.left;
        visibleRect.origin.y = tableView.contentOffset.y + tableView.contentInset.top;

        CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
        BOOL searchBarIsVisible = CGRectIntersectsRect(visibleRect, searchBarFrame);

        if (searchBarIsVisible) {
            if (self.navigationItem.rightBarButtonItem) {
                [self.navigationItem setRightBarButtonItem:nil animated:YES];
            }
        } else {
            if (!self.navigationItem.rightBarButtonItem) {
                UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                            target:self
                                                                                            action:@selector(searchButtonTapped:)];
                [self.navigationItem setRightBarButtonItem:searchItem animated:YES];
            }
        }

        self.needsNavigationItemUpdate = NO;
    }
}

#pragma mark Responding to UI events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

    if (category) {
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *localCategory = (MITNewsCategory*)[self.managedObjectContext objectWithID:[category objectID]];
            DDLogVerbose(@"Recieved tap on section header for category with name '%@'",localCategory.name);
        }];

        [self performSegueWithIdentifier:@"showCategoryDetail" sender:gestureRecognizer];
    }

}

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
    searchBarFrame.size = CGSizeMake(1, 1);

    [self.tableView scrollRectToVisible:searchBarFrame animated:NO];
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (IBAction)loadMoreFooterTapped:(id)sender
{
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;

        __weak UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView*)gestureRecognizer.view;
        __weak UITableView *tableView = nil;
        NSString *queryString = nil;
        __block NSString *categoryName = nil;
        NSUInteger offset = 0;

        if (self.tableView.tableFooterView == footerView) {
            tableView = self.tableView;
            offset = [self.fetchedResultsController.fetchedObjects count];

            [self.managedObjectContext performBlockAndWait:^{
                MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];
                categoryName = category.identifier;
            }];
        } else if (self.searchDisplayController.searchResultsTableView.tableFooterView == footerView) {
            tableView = self.searchDisplayController.searchResultsTableView;
            queryString = self.searchQuery;
            offset = [self.searchResults count];
        }

        if (footerView.textLabel.isEnabled) {
            footerView.textLabel.enabled = NO;

            __weak MITNewsStoriesViewController *weakSelf = self;
            [[MITNewsModelController sharedController] storiesInCategory:categoryName
                                                                   query:queryString
                                                                  offset:offset
                                                                   limit:20
                                                              completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
                                                                  MITNewsStoriesViewController *blockSelf = weakSelf;
                                                                  if (blockSelf && footerView) {
                                                                      if (queryString) {
                                                                          NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(offset, [stories count])];
                                                                          [blockSelf.searchResults insertObjects:stories atIndexes:insertedIndexes];
                                                                      }

                                                                      footerView.textLabel.enabled = YES;
                                                                      [tableView reloadData];
                                                                  }
                                                              }];
        }
    }
}

#pragma mark Loading & updating, and retrieving data
- (void)performDataUpdate:(void (^)(NSError *error))completion
{
    if (!self.isUpdating) {
        self.updating = YES;

        __block NSString *categoryIdentifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];
            categoryIdentifier = category.identifier;
        }];

        __weak MITNewsStoriesViewController *weakSelf = self;
        MITNewsModelController *modelController = [MITNewsModelController sharedController];
        [modelController storiesInCategory:categoryIdentifier
                                     query:nil
                                    offset:0
                                     limit:20
                                completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                    MITNewsStoriesViewController *blockSelf = weakSelf;
                                    if (blockSelf) {
                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                            blockSelf.updating = NO;

                                            if (error) {
                                                [self setUpdateText:@"Update failed" animated:NO];
                                            } else {
                                                NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:[NSDate date]
                                                                                                                    toDate:[NSDate date]];
                                                NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
                                                [self setUpdateText:updateText animated:NO];
                                            }

                                            if (completion) {
                                                completion(error);
                                            }
                                        }];
                                    }
                                }];
    }
}

- (void)loadSearchResultsForQuery:(NSString*)query loaded:(void (^)(NSError *error))completion
{
    if ([query length] == 0) {
        self.searchQuery = nil;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.searchResults = [[NSMutableArray alloc] init];

            if (completion) {
                completion(nil);
            }
        }];
    }

    if (![self.searchQuery isEqualToString:query]) {
        NSString *currentQuery = self.searchQuery;

        MITNewsModelController *modelController = [MITNewsModelController sharedController];
        __weak MITNewsStoriesViewController *weakSelf = self;
        [modelController storiesInCategory:nil
                                     query:query
                                    offset:0
                                     limit:20
                                completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                    MITNewsStoriesViewController *blockSelf = weakSelf;
                                    if (blockSelf && (blockSelf.searchQuery == currentQuery)) {
                                        blockSelf.searchQuery = query;

                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                            blockSelf.searchResults = [[NSMutableArray alloc] initWithArray:stories];

                                            if (completion) {
                                                completion(error);
                                            }
                                        }];
                                    }
                                }];
    }
}

- (MITNewsStory*)selectedStory
{
    UITableView *tableView = nil;

    if (self.searchDisplayController.isActive) {
        tableView = self.searchDisplayController.searchResultsTableView;
    } else {
        tableView = self.tableView;
    }

    NSIndexPath* selectedIndexPath = [tableView indexPathForSelectedRow];
    return [self storyAtIndexPath:selectedIndexPath inTableView:tableView];
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView
{
    NSUInteger row = (NSUInteger)indexPath.row;

    if (tableView == self.tableView) {
        return self.fetchedResultsController.fetchedObjects[row];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults[row];
    } else {
        return nil;
    }
}

- (NSString*)tableViewCellIdentifierForStory:(MITNewsStory*)story
{
    __block NSString *identifier = nil;
    if (story) {
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];

            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                identifier = MITNewsStoryExternalCellIdentifier;
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
    }

    return identifier;
}


- (MITNewsStoryCell*)sizingCellForIdentifier:(NSString *)identifier
{
    MITNewsStoryCell *sizingCell = [self.sizingCellsByIdentifier objectForKey:identifier];

    if (!sizingCell) {
        UINib *cellNib = nil;
        if ([identifier isEqualToString:MITNewsStoryCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil];
        } else if ([identifier isEqualToString:MITNewsStoryNoDekCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil];
        } else if ([identifier isEqualToString:MITNewsStoryExternalCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil];
        }

        sizingCell = [[cellNib instantiateWithOwner:sizingCell options:nil] firstObject];
        sizingCell.hidden = YES;
        sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.tableView addSubview:sizingCell];
        [self.sizingCellsByIdentifier setObject:sizingCell forKey:identifier];
    }
    
    sizingCell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 84.);
    return sizingCell;
}

#pragma mark - UITableView
- (UITableViewHeaderFooterView*)createLoadMoreFooterView
{
    UITableViewHeaderFooterView* tableFooter = [[UITableViewHeaderFooterView alloc] init];
    tableFooter.frame = CGRectMake(0, 0, 320, 44);

    tableFooter.textLabel.textColor = [UIColor MITTintColor];
    tableFooter.textLabel.font = [UIFont boldSystemFontOfSize:16.];
    tableFooter.textLabel.text = @"Load more items...";

    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadMoreFooterTapped:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [tableFooter addGestureRecognizer:tapRecognizer];
    [tableFooter sizeToFit];

    return tableFooter;
}

#pragma mark UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self respondsToSelector:@selector(setNeedsNavigationItemUpdate)]) {
        [self performSelector:@selector(setNeedsNavigationItemUpdate)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 22.;
    } else {
        return 0.;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.searchQuery) {
            UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsSearchHeader"];

            if (!headerView) {
                headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"NewsSearchHeader"];
            }

            headerView.textLabel.text = [NSString stringWithFormat:@"results for '%@'",self.searchQuery];
            return  headerView;
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        [storyCell.storyImageView cancelCurrentImageLoad];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath inTableView:tableView];

    if (story) {
        NSString *identifier = [self tableViewCellIdentifierForStory:story];
        MITNewsStoryCell *sizingCell = [self sizingCellForIdentifier:identifier];
        [self configureCell:sizingCell forStory:story];

        [sizingCell setNeedsLayout];
        [sizingCell layoutIfNeeded];

        CGSize rowSize = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

		return MAX(86.,ceil(rowSize.height));
    }

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showStoryDetail" sender:tableView];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;
        return (fetchedObjects ? 1 : 0);
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;
        return (fetchedObjects ? [fetchedObjects count] : 0);
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? [self.searchResults count] : 0);
    }

    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *newsStory = [self storyAtIndexPath:indexPath inTableView:tableView];
    NSString *identifier = [self tableViewCellIdentifierForStory:newsStory];

    NSAssert(identifier,@"[%@] missing UITableViewCell identifier in %@",self,NSStringFromSelector(_cmd));

    MITNewsStoryCell *cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self configureCell:cell forStory:newsStory];
    return cell;
}

- (void)configureCell:(UITableViewCell*)cell forStory:(MITNewsStory*)newsStory
{
    __block NSString *title = nil;
    __block NSString *dek = nil;
    __block NSURL *imageURL = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *story = (MITNewsStory*)[self.managedObjectContext objectWithID:[newsStory objectID]];
        title = story.title;
        dek = story.dek;

        MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:cell.imageView.bounds.size];
        imageURL = representation.url;
    }];


    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
    if (title) {
        NSError *error = nil;
        NSString *titleContent = [title stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
        if (!titleContent) {
            DDLogWarn(@"failed to sanitize title, falling back to the original content: %@",error);
            titleContent = title;
        }

        //storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleContent
        //                                                                      attributes:[MITNewsViewController titleTextAttributes]];
        storyCell.titleLabel.text = titleContent;
    } else {
        storyCell.titleLabel.text = nil;
    }

    if (dek) {
        NSError *error = nil;
        NSString *dekContent = [dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
        if (error) {
            DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
            dekContent = dek;
        }

        //storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:dekContent attributes:[MITNewsViewController dekTextAttributes]];
        storyCell.dekLabel.text = dekContent;
    } else {
        storyCell.dekLabel.text = nil;
    }


    if (imageURL) {
        [storyCell.storyImageView setImageWithURL:imageURL];
    } else {
        storyCell.storyImageView.image = nil;
    }
}

#pragma mark - UISearchDisplayController
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.searching = YES;
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView reloadData];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searching = NO;
    self.searchResults = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if ([searchString length] == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSString *searchQuery = searchBar.text;

    __weak UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    searchDisplayController.searchResultsTableView.tableFooterView = nil;

    UIColor *textColor = nil;
    if ([self.view respondsToSelector:@selector(tintColor)]) {
        textColor = self.view.tintColor;
    } else {
        textColor = [UIColor MITTintColor];
    }

    [self loadSearchResultsForQuery:searchQuery loaded:^(NSError *error) {
        if (!searchDisplayController.searchResultsTableView.tableFooterView) {
            searchDisplayController.searchResultsTableView.tableFooterView = [self createLoadMoreFooterView];
        }
        
        [searchDisplayController.searchResultsTableView reloadData];
    }];
}
@end
