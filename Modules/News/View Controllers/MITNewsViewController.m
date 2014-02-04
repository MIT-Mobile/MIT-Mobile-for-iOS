#import "MITNewsViewController.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsStoriesViewController.h"
#import "MITNewsModelController.h"
#import "MITNewsStoryCell.h"
#import "MITDisclosureHeaderView.h"
#import "UIImageView+WebCache.h"

#import "MITAdditions.h"

// The below values were pulled from the News storyboard.
// Either change them if the storyboard changes or find a way
// to dynamically extract them.
static const CGFloat MITNewsStoryCellMinimumHeight = 86.;
static const CGFloat MITNewsStoryCellMaximumTextWidth = 196.;
static const CGSize MITNewsStoryCellDefaultImageSize = {.width = 86., .height = 61.};

static NSString* const MITNewsStoryFeaturedStoriesToken = @"MITNewsFeaturedStories";

@interface MITNewsViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic,getter = isUpdating) BOOL updating;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;

@property (nonatomic,strong) NSFetchedResultsController *featuredStoriesFetchedResultsController;
@property (nonatomic,strong) NSFetchedResultsController *categoriesFetchedResultsController;
@property (nonatomic,strong) NSMutableArray *searchResults;

@property (nonatomic,strong) NSHashTable *inFlightDataRequests;
@property (nonatomic,strong) NSMapTable *cachedStoriesByCategory;

+ (NSDictionary*)headerTextAttributes;
+ (NSDictionary*)titleTextAttributes;
+ (NSDictionary*)dekTextAttributes;

- (void)loadFetchedResultsControllers;
@end

@implementation MITNewsViewController

#pragma mark UI Element text attributes
// TODO: Look for an alternate spot for these. UIAppearance or a utility class maybe?
// Figure out how much we are going to be reusing these
+ (NSDictionary*)headerTextAttributes
{
    return @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.],
             NSForegroundColorAttributeName: [UIColor darkTextColor]};
}

+ (NSDictionary*)titleTextAttributes
{
    return @{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

+ (NSDictionary*)dekTextAttributes
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:12.],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

+ (NSDictionary*)updateItemTextAttributes
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:[UIFont smallSystemFontSize]],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

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
	// Do any additional setup after loading the view.
    self.numberOfStoriesPerCategory = 3;
    self.showFeaturedStoriesSection = YES;

    [self.tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NewsCategoryHeader"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:@"StoryNoDekCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:@"StoryExternalCell"];

    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];

    self.tableView.tableHeaderView = self.searchDisplayController.searchBar;
    self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchDisplayController.searchBar.frame));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadFetchedResultsControllers];

    NSError *fetchError = nil;
    [self.featuredStoriesFetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
    }

    fetchError = nil;
    [self.categoriesFetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
    }

    self.updating = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performDataUpdate];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];
    
    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);
    
    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        //NSAssert([destinationViewController isKindOfClass:[MITNewsStoryDetailViewController class]],@"expected view controller of type %@, got %@",NSStringFromClass([MITNewsStoryDetailViewController class]),NSStringFromClass([destinationViewController class]));
        //MITNewsStoryDetailViewController *storyDetailViewController = (MITNewsStoryDetailViewController*)destinationViewController;
    } else if ([segue.identifier isEqualToString:@"showCategoryDetail"]) {
        NSAssert([destinationViewController isKindOfClass:[MITNewsStoriesViewController class]],@"expected view controller of type %@, got %@",NSStringFromClass([MITNewsStoriesViewController class]),NSStringFromClass([destinationViewController class]));
        MITNewsStoriesViewController *storiesViewController = (MITNewsStoriesViewController*)destinationViewController;
        storiesViewController.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];

        UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;
        MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];
        storiesViewController.category = category;
    }
}

#pragma mark Notifications
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark View Orientation
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Property Setters & Getters
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }

    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark Updating state
- (void)setUpdating:(BOOL)updating
{
    [self setUpdating:updating animated:YES];
}

- (void)setUpdating:(BOOL)updating animated:(BOOL)animated
{
    if (_updating != updating) {
        if (updating) {
            [self willBeginUpdating:animated];
        }
        
        _updating = updating;
        
        if (!_updating) {
            [self didEndUpdating:animated];
        }
        
    }
}

- (void)willBeginUpdating:(BOOL)animated
{
    [self setUpdateText:@"Updating..." animated:animated];
}

- (void)didEndUpdating:(BOOL)animated
{
    NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:[NSDate date]
                                                                        toDate:[NSDate date]];
    NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
    [self setUpdateText:updateText animated:animated];
}

- (void)setUpdateText:(NSString*)string animated:(BOOL)animated
{
    if (self.navigationController.toolbarHidden) {
        self.navigationController.toolbarHidden = NO;
    }
    
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.attributedText = [[NSAttributedString alloc] initWithString:string attributes:[MITNewsViewController updateItemTextAttributes]];
    [updatingLabel sizeToFit];
    
    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark UI Events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];
    if (category) {
        DDLogVerbose(@"Recieved tap on section header for category with name '%@'",category.name);
        [self performSegueWithIdentifier:@"showCategoryDetail" sender:gestureRecognizer];
    }
}

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

#pragma mark Table data helpers
- (void)loadFetchedResultsControllers
{
    // Featured fetched results controller
    if (self.showFeaturedStoriesSection && !self.featuredStoriesFetchedResultsController) {
        NSFetchRequest *featuredStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        featuredStories.predicate = [NSPredicate predicateWithFormat:@"featured == YES"];
        featuredStories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                            [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:featuredStories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.featuredStoriesFetchedResultsController = fetchedResultsController;
    }

    if (!self.categoriesFetchedResultsController) {
        NSFetchRequest *categories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:NO]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:@"name"
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.categoriesFetchedResultsController = fetchedResultsController;
    }
}

- (void)performDataUpdate
{
    if ([self.inFlightDataRequests count] == 0) {
        if (!self.inFlightDataRequests) {
            self.inFlightDataRequests = [NSHashTable weakObjectsHashTable];
        }

        self.updating = YES;

        MITNewsModelController *modelController = [MITNewsModelController sharedController];

        [self.inFlightDataRequests addObject:MITNewsStoryFeaturedStoriesToken];
        [modelController featuredStoriesWithOffset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {

                                            [self.inFlightDataRequests removeObject:MITNewsStoryFeaturedStoriesToken];
                                            if ([self.inFlightDataRequests count] == 0) {
                                                [self setUpdating:NO animated:YES];
                                            }
                                        }];

        [modelController categories:^(NSArray *categories, NSError *error) {
            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                [self.inFlightDataRequests addObject:category];

                [modelController storiesInCategory:category.identifier
                                             query:nil
                                            offset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            [self.inFlightDataRequests removeObject:category];
                                            if ([self.inFlightDataRequests count] == 0) {
                                                [self setUpdating:NO animated:YES];
                                            }
                                        }];
            }];
        }];
    }
}

- (NSArray*)storiesInCategory:(MITNewsCategory*)category
{
    if (!self.cachedStoriesByCategory) {
        self.cachedStoriesByCategory = [NSMapTable weakToStrongObjectsMapTable];
    }

    NSArray *cachedStories = [self.cachedStoriesByCategory objectForKey:category];

    if (!cachedStories) {
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        cachedStories = [category.stories sortedArrayUsingDescriptors:sortDescriptors];
        [self.cachedStoriesByCategory setObject:cachedStories forKey:category];
    }

    return cachedStories;
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = nil;

    if (self.showFeaturedStoriesSection && (indexPath.section == 0)) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.featuredStoriesFetchedResultsController sections][indexPath.section];
        story = (MITNewsStory*)[sectionInfo objects][indexPath.row];
    } else {
        NSInteger section = indexPath.section;
        if (self.showFeaturedStoriesSection) {
            section -= 1;
        }

        id<NSFetchedResultsSectionInfo> sectionInfo = [self.categoriesFetchedResultsController sections][section];
        MITNewsCategory *sectionCategory = [sectionInfo objects][0];

        NSArray *stories = [self storiesInCategory:sectionCategory];
        story = stories[indexPath.row];
    }

    return story;
}

#pragma mark - NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {

}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.inFlightDataRequests count] == 0) {
        if (controller == self.featuredStoriesFetchedResultsController) {
            [self.cachedStoriesByCategory removeAllObjects];
        }

        [self setUpdating:NO animated:YES];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Featured Stories" attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = YES;
            return headerView;
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
            id<NSFetchedResultsSectionInfo> sectionInfo = [self.categoriesFetchedResultsController sections][section];
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:[sectionInfo name] attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = NO;
            return  headerView;
        }
    } else {
        return nil;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
            if (!(self.showFeaturedStoriesSection && (section == 0))) {
                UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)view;

                UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];

                [headerView addGestureRecognizer:gesture];
                [self.gestureRecognizersByView setObject:gesture forKey:view];

                NSInteger actualSection = section;
                if (self.featuredStoriesFetchedResultsController) {
                    --actualSection;
                }

                MITNewsCategory *categoryObject = (MITNewsCategory*)[self.categoriesFetchedResultsController fetchedObjects][actualSection];
                [self.categoriesByGestureRecognizer setObject:categoryObject forKey:gesture];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
            UIGestureRecognizer *gesture = [self.gestureRecognizersByView objectForKey:view];
            
            [view removeGestureRecognizer:gesture];
            [self.gestureRecognizersByView removeObjectForKey:gesture];
            [self.categoriesByGestureRecognizer removeObjectForKey:gesture];
        }
    }
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
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }
    
    if (story) {
        CGFloat titleHeight = 0.;
        if ([story.title length]) {
            NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsViewController titleTextAttributes]];
            
            CGRect titleRect = [titleString boundingRectWithSize:CGSizeMake(MITNewsStoryCellMaximumTextWidth, CGFLOAT_MAX)
                                                         options:(NSStringDrawingUsesFontLeading |
                                                                  NSStringDrawingUsesLineFragmentOrigin)
                                                         context:nil];
            titleHeight = ceil(CGRectGetHeight(titleRect));
        }

        CGFloat dekHeight = 0.;
        if ([story.dek length]) {
            NSAttributedString *dekString = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsViewController dekTextAttributes]];
            CGRect dekRect = [dekString boundingRectWithSize:CGSizeMake(MITNewsStoryCellMaximumTextWidth, CGFLOAT_MAX)
                                                     options:(NSStringDrawingUsesFontLeading |
                                                              NSStringDrawingUsesLineFragmentOrigin)
                                                     context:nil];
            dekHeight = ceil(CGRectGetHeight(dekRect));
        }

        CGFloat totalVerticalPadding = 23.;
        if ((titleHeight >= 1) && (dekHeight >= 1)) {
            totalVerticalPadding += 4.;
        }

        return MAX(MITNewsStoryCellMinimumHeight,titleHeight + dekHeight + totalVerticalPadding);
    } else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSInteger numberOfSections = 0;

        if (self.showFeaturedStoriesSection) {
            numberOfSections += 1;
        }

        numberOfSections += [[self.categoriesFetchedResultsController sections] count];
        return numberOfSections;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self.featuredStoriesFetchedResultsController sections][section];
            return MIN(self.numberOfStoriesPerCategory,[sectionInfo numberOfObjects]);
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            id<NSFetchedResultsSectionInfo> sectionInfo = [self.categoriesFetchedResultsController sections][section];
            NSArray *storiesInCategory = [self storiesInCategory:[sectionInfo objects][0]];
            return MIN(self.numberOfStoriesPerCategory,[storiesInCategory count]);
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? [self.searchResults count] : 0);
    }
    
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }
    
    if (story) {
        NSString *identifier = nil;
        
        // TODO: Add logic to handle the StoryExternalCell.
        //  Right now there is no way to determine which cells are
        //  external so they'll just appear as StoryCells with
        //  no title, a dek and an image.
        // (2014.01.22 - bskinner)
        if ([story.dek length]) {
            identifier = @"StoryCell";
        } else {
            identifier = @"StoryNoDekCell";
        }

        MITNewsStoryCell *cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [self configureCell:cell forRowAtIndexPath:indexPath tableView:tableView];
        return cell;
    } else {
        return nil;
    }
}

- (void)configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView
{
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }

    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;

    storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsViewController titleTextAttributes]];
    
    if ([story.dek length]) {
        storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsViewController dekTextAttributes]];
    }
    
    MITNewsImageRepresentation *representation = [story.coverImage bestImageForSize:MITNewsStoryCellDefaultImageSize];
    [storyCell.storyImageView setImageWithURL:representation.url];
}

#pragma mark - UISearchDisplayController
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    self.searching = NO;
}

#pragma mark UISearchBarDelegate

@end
