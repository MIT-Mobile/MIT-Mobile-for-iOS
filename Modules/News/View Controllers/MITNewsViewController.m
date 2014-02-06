#import "MITNewsViewController.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsStoryViewController.h"
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
}

- (void)viewWillAppear:(BOOL)animated
{
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
    
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
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
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
            
            NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
            MITNewsStory *story = [self storyAtIndexPath:selectedIndexPath];
            
            storyDetailViewController.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            storyDetailViewController.story = story;
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else if ([segue.identifier isEqualToString:@"showCategoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoriesViewController class]]) {
            MITNewsStoriesViewController *storiesViewController = (MITNewsStoriesViewController*)destinationViewController;
            storiesViewController.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];

            UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;
            MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];
            
            storiesViewController.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            storiesViewController.category = category;
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoriesViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
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
    [self.tableView reloadData];
}

- (void)setUpdateText:(NSString*)string animated:(BOOL)animated
{
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
    self.searchDisplayController.active = YES;
}

#pragma mark Table data helpers
- (void)loadFetchedResultsControllers
{
    // Featured fetched results controller
    if (self.showFeaturedStoriesSection && !self.featuredStoriesFetchedResultsController) {
        NSFetchRequest *featuredStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        featuredStories.predicate = [NSPredicate predicateWithFormat:@"featured == NO"];
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
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
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
                
                __weak MITNewsViewController *weakSelf = self;
                [modelController storiesInCategory:category.identifier
                                             query:nil
                                            offset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            MITNewsViewController *blockSelf = weakSelf;
                                            if (blockSelf) {
                                                [blockSelf.inFlightDataRequests removeObject:category];

                                                if ([blockSelf.inFlightDataRequests count] == 0) {
                                                    [self setUpdating:NO animated:YES];
                                                }
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
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{

}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{

}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Featured Stories"
                                                                                  attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = YES;
            
            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
            if (recognizer) {
                [self.categoriesByGestureRecognizer removeObjectForKey:recognizer];
                [headerView removeGestureRecognizer:recognizer];
            }
            
            return headerView;
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
            NSArray *categories = [self.categoriesFetchedResultsController fetchedObjects];
            MITNewsCategory *category = categories[section];
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:category.name
                                                                                  attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = NO;
            
            UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
            [headerView addGestureRecognizer:gesture];
            
            [self.categoriesByGestureRecognizer setObject:category forKey:gesture];
            
            // Keep track of the gesture recognizers we create so we can remove
            // them later
            [self.gestureRecognizersByView setObject:gesture forKey:headerView];
            return headerView;
        }
    } else {
        return nil;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showStoryDetail" sender:self];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSInteger numberOfSections = 0;

        if (self.showFeaturedStoriesSection) {
            numberOfSections += 1;
        }

        numberOfSections += [[self.categoriesFetchedResultsController fetchedObjects] count];
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
            NSArray *stories = [self.featuredStoriesFetchedResultsController fetchedObjects];
            return MIN(self.numberOfStoriesPerCategory,[stories count]);
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            MITNewsCategory *category = [self.categoriesFetchedResultsController fetchedObjects][section];
            NSArray *storiesInCategory = [self storiesInCategory:category];
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
    
    MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:MITNewsStoryCellDefaultImageSize];

    if (representation) {
        [storyCell.storyImageView setImageWithURL:representation.url];
    }
}

#pragma mark - UISearchDisplayController
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self.view addSubview:controller.searchBar];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    
}

#pragma mark UISearchBarDelegate

@end
