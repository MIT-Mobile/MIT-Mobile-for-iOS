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

static const NSInteger MITNewsStoryCellMinimumHeight = 86.;
static const NSInteger MITNewsStoryCellMaximumTextWidth = 196.;

static NSString const *MITNewsCategoryAssociatedObjectKey = @"MITNewsCategoryAssociatedObjectKey";

@interface MITNewsViewController (MITNewsViewControllerSections)
- (NSFetchedResultsController*)fetchedResultsControllerForTableViewSection:(NSInteger)section;
- (NSFetchedResultsController*)fetchedResultsControllerForTableViewSection:(NSInteger)section fetchedResultsSection:(out NSInteger*)frcSection;
- (NSInteger)offsetForSectionAtIndex:(NSInteger)section inFetchedResultsController:(NSFetchedResultsController*)controller;

- (void)willInsertFetchedResultsController:(NSFetchedResultsController*)controller atIndex:(NSUInteger)index;
- (void)didInsertFetchedResultController:(NSFetchedResultsController*)controller;
- (void)willRemoveFetchedResultsController:(NSFetchedResultsController*)controller;
- (void)didRemoveFetchedResultsController:(NSFetchedResultsController*)controller atIndex:(NSUInteger)index;
@end

@interface MITNewsViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;

@property (nonatomic,strong) NSMutableArray *fetchedResultsControllers;

// Used to make sure that we are invoking -[UITableView reloadData] as little as possible
// This is used in the NSFetchedResultsTableView willChange/didChange methods to
// keep track of overlapping updates.
@property NSUInteger tableUpdateCounter;

+ (NSDictionary*)headerTextAttributes;
+ (NSDictionary*)titleTextAttributes;
+ (NSDictionary*)dekTextAttributes;

- (void)loadFetchedResultsControllers;
@end

@implementation MITNewsViewController
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
    [super viewWillAppear:animated];

    if (!self.fetchedResultsControllers) {
        [self loadFetchedResultsControllers];
        MITNewsModelController *modelController = [MITNewsModelController sharedController];
        [modelController categories:^(NSArray *categories, NSError *error) {
            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                [modelController storiesInCategory:category
                                         batchSize:20
                                        completion:nil];
            }];
        }];
    }

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
        NSInteger fetchedResultsSection = NSNotFound;

        // See if there is a better way to do this. Passing around state in the UIGestureRecognizer using the
        // view's tag seems a bit hackish
        // (bskinner-2014.01.27
        NSFetchedResultsController *controller = [self fetchedResultsControllerForTableViewSection:gestureRecognizer.view.tag
                                                                             fetchedResultsSection:&fetchedResultsSection];

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

#pragma mark UI Events
- (IBAction)handleSectionHeaderTap:(UIGestureRecognizer *)gestureRecognizer
{
    NSInteger section = gestureRecognizer.view.tag;
    
    if (gestureRecognizer.view.tag != NSNotFound) {
        if (self.showFeaturedStoriesSection && section == 0) {
            return;
        } else {
            NSInteger fetchedResultsSection = NSNotFound;
            NSFetchedResultsController *controller = [self fetchedResultsControllerForTableViewSection:section fetchedResultsSection:&fetchedResultsSection];
            DDLogVerbose(@"Recieved tap on section header for category with name '%@'",[[controller sections][fetchedResultsSection] name]);

            [self performSegueWithIdentifier:@"showCategoryDetail" sender:gestureRecognizer];
        }
    }
}

#pragma mark Table data helpers
- (void)loadFetchedResultsControllers
{
    NSMutableArray *fetchedResultsControllers = [[NSMutableArray alloc] init];
    NSArray *baseSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

    // Featured fetched results controller
    if (self.showFeaturedStoriesSection) {
        NSFetchRequest *featuredStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        featuredStories.predicate = [NSPredicate predicateWithFormat:@"featured == YES"];
        featuredStories.sortDescriptors = [baseSortDescriptors copy];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:featuredStories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;

        NSError *fetchError = nil;
        [fetchedResultsController performFetch:&fetchError];

        if (fetchError) {
            DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
        } else {
            [fetchedResultsControllers addObject:fetchedResultsController];
        }
    }

    {
        NSFetchRequest *categories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"category.order" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:@"category.name"
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;

        NSError *fetchError = nil;
        [fetchedResultsController performFetch:&fetchError];

        if (fetchError) {
            DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
        } else {
            [fetchedResultsControllers addObject:fetchedResultsController];
        }
    }

    /*
    {
        NSFetchRequest *normalStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        NSMutableArray *predicates = [NSMutableArray arrayWithObject:[NSPredicate predicateWithFormat:@"category != nil"]];
        
        if (self.showFeaturedStoriesSection) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"featured == NO"]];
        }
        
        normalStories.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

        NSMutableArray *sortDescriptors = [baseSortDescriptors mutableCopy];
        [sortDescriptors insertObject:[NSSortDescriptor sortDescriptorWithKey:@"category.identifier" ascending:YES]
                              atIndex:0];
        normalStories.sortDescriptors = sortDescriptors;

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:normalStories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:@"category.name"
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;

        NSError *fetchError = nil;
        [fetchedResultsController performFetch:&fetchError];

        if (fetchError) {
            DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
        } else {
            [fetchedResultsControllers addObject:fetchedResultsController];
        }
    }
    */

    self.fetchedResultsControllers = fetchedResultsControllers;

    if ([self isViewLoaded]) {
        [self.tableView reloadData];
    }
}

#pragma mark - Delegate Methods
#pragma mark NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    ++self.tableUpdateCounter;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    --self.tableUpdateCounter;

    if (self.tableUpdateCounter == 0) {
        [self.tableView reloadData];
    }
}

#pragma mark UITableViewDelegate
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSInteger fetchedResultsSectionNumber = NSNotFound;
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableViewSection:section fetchedResultsSection:&fetchedResultsSectionNumber];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:fetchedResultsSectionNumber];
    
    if ((section == 0) || [sectionInfo name]) {
        MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
        
        if (section == 0) {
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Featured Stories" attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = YES;
        } else {
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:[sectionInfo name] attributes:[MITNewsViewController headerTextAttributes]];
        }
        
        return headerView;
    } else {
        return nil;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)view;
        
        UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSectionHeaderTap:)];

        NSInteger fetchControllerSection = NSNotFound;
        NSFetchedResultsController *controller = [self fetchedResultsControllerForTableViewSection:section fetchedResultsSection:&fetchControllerSection];
        
        [headerView addGestureRecognizer:gesture];
        [self.gestureRecognizersByView setObject:gesture forKey:view];
        view.tag = section;
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UIGestureRecognizer *gesture = [self.gestureRecognizersByView objectForKey:view];
        
        [view removeGestureRecognizer:gesture];
        [self.gestureRecognizersByView removeObjectForKey:gesture];
        view.tag = NSNotFound;
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
    NSInteger fetchedResultsSectionNumber = NSNotFound;
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableViewSection:indexPath.section fetchedResultsSection:&fetchedResultsSectionNumber];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:fetchedResultsSectionNumber];
    
    MITNewsStory *story = [sectionInfo objects][indexPath.row];
    
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
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        __block NSInteger numberOfSections = 0;
        [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *controller, NSUInteger idx, BOOL *stop) {
            numberOfSections += [[controller sections] count];
        }];
        
        return numberOfSections;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        NSInteger fetchedResultsSectionNumber = NSNotFound;
        NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableViewSection:section fetchedResultsSection:&fetchedResultsSectionNumber];
        id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:fetchedResultsSectionNumber];
        return MIN(self.numberOfStoriesPerCategory,[sectionInfo numberOfObjects]);
    } else {
        return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger fetchedResultsSectionNumber = NSNotFound;
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableViewSection:indexPath.section fetchedResultsSection:&fetchedResultsSectionNumber];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:fetchedResultsSectionNumber];
    MITNewsStory *story = [sectionInfo objects][indexPath.row];
    
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
}

- (void)configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView
{
    NSInteger fetchedResultsSectionNumber = NSNotFound;
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableViewSection:indexPath.section fetchedResultsSection:&fetchedResultsSectionNumber];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:fetchedResultsSectionNumber];
    MITNewsStory *story = [sectionInfo objects][indexPath.row];
    
    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;

    storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsViewController titleTextAttributes]];
    
    if ([story.dek length]) {
        storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsViewController dekTextAttributes]];
    }
    
    __block NSURL *imageURL = nil;
    [story.images enumerateObjectsUsingBlock:^(MITNewsImage *image, BOOL *stop) {
        [image.representations enumerateObjectsUsingBlock:^(MITNewsImageRepresentation *imageRepresentation, BOOL *stop) {
            if ([imageRepresentation.name isEqualToString:@"small"]) {
                imageURL = imageRepresentation.url;
                (*stop) = YES;
            }
        }];
        
        if (imageURL) {
            (*stop) = YES;
        }
    }];
    
    if (imageURL) {
        [storyCell.storyImageView setImageWithURL:imageURL];
    }
}

@end

@implementation MITNewsViewController (MITNewsViewControllerSections)
- (NSInteger)offsetForSectionAtIndex:(NSInteger)section inFetchedResultsController:(NSFetchedResultsController*)controller
{
    __block NSInteger sectionOffset = 0;
    
    NSAssert([self.fetchedResultsControllers containsObject:controller], @"FRC %@ does not exist yet!",controller);
    
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *fetchedResultController, NSUInteger idx, BOOL *stop) {
        if ([controller isEqual:fetchedResultController]) {
            (*stop) = YES;
        } else {
            sectionOffset += [[fetchedResultController sections] count];
        }
    }];

    return sectionOffset;
}

- (NSFetchedResultsController*)fetchedResultsControllerForTableViewSection:(NSInteger)section
{
    return [self fetchedResultsControllerForTableViewSection:section fetchedResultsSection:NULL];
}

- (NSFetchedResultsController*)fetchedResultsControllerForTableViewSection:(NSInteger)section fetchedResultsSection:(out NSInteger*)frcSection
{
    __block NSFetchedResultsController *returnedFetchedResultsController = nil;
    __block NSUInteger sectionCount = 0;
    
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *fetchedResultController, NSUInteger idx, BOOL *stop) {
        sectionCount += [[fetchedResultController sections] count];
        
        if (section < sectionCount) {
            returnedFetchedResultsController = fetchedResultController;
            if (frcSection) {
                (*frcSection) = (sectionCount - section) - 1;
            }
            
            (*stop) = YES;
        }
    }];
    
    return returnedFetchedResultsController;
}

- (void)willInsertFetchedResultsController:(NSFetchedResultsController*)controller atIndex:(NSUInteger)index
{
    
}

- (void)didInsertFetchedResultController:(NSFetchedResultsController*)controller
{
    if ([self isViewLoaded]) {
        NSError *error = nil;
        BOOL fetchSucceeded = [controller performFetch:&error];
        
        if (!fetchSucceeded) {
            DDLogWarn(@"<%@> fetch failed with error: %@",controller,error);
        }
    }
}

- (void)willRemoveFetchedResultsController:(NSFetchedResultsController*)controller
{
    
}

- (void)didRemoveFetchedResultsController:(NSFetchedResultsController*)controller atIndex:(NSUInteger)index
{
    
}

@end
