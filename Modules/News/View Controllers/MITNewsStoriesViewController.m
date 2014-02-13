#import "MITNewsStoriesViewController.h"
#import "MITNewsStoryCell.h"
#import "MITCoreData.h"

#import "MITAdditions.h"

#import "MITNewsModelController.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsCategory.h"
#import "MITNewsStory.h"

#import "UIImageView+WebCache.h"

static const CGFloat MITNewsStoryCellMinimumHeight = 86.;
static const CGFloat MITNewsStoryCellMaximumTextWidth = 196.;
static const CGSize MITNewsStoryCellDefaultImageSize = {.width = 86., .height = 61.};

@interface MITNewsStoriesViewController ()
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,strong) NSMapTable *footerGestureRecognizers;
@property (nonatomic,strong) NSMutableIndexSet *sectionsWithActiveRequests;

@end

@implementation MITNewsStoriesViewController
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
    
    self.footerGestureRecognizers = [NSMapTable weakToWeakObjectsMapTable];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:@"StoryNoDekCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:@"StoryExternalCell"];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"LoadMoreFooter"];
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
    updatingLabel.attributedText = [[NSAttributedString alloc] initWithString:string attributes:[MITNewsStoriesViewController updateItemTextAttributes]];
    [updatingLabel sizeToFit];
    
    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark UI Actions
- (IBAction)loadMoreStories:(id)sender
{
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer* gestureRecognizer = (UIGestureRecognizer*)sender;
        
        if ([gestureRecognizer.view isKindOfClass:[UITableViewHeaderFooterView class]]) {
            __weak UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView*)gestureRecognizer.view;
            
            NSInteger section = footerView.tag;
            if (![self.sectionsWithActiveRequests containsIndex:section]) {
                NSInteger numberOfRows = [self.tableView numberOfRowsInSection:section];
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     footerView.textLabel.enabled = NO;
                                     [self setUpdating:YES animated:NO];
                                 }];
                
                __block NSString *categoryIdentifier = nil;
                [self.managedObjectContext performBlockAndWait:^{
                    categoryIdentifier = self.category.identifier;
                }];
                
                __weak MITNewsStoriesViewController *weakSelf = self;
                [[MITNewsModelController sharedController] storiesInCategory:categoryIdentifier
                                                                       query:nil
                                                                      offset:numberOfRows
                                                                       limit:20
                                                                  completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                                                      MITNewsStoriesViewController* blockSelf = weakSelf;
                                                                      UITableViewHeaderFooterView* blockView = footerView;
                                                                      
                                                                      if (blockSelf && blockView) {
                                                                          if (blockView.tag == section) {
                                                                              [UIView animateWithDuration:0.25
                                                                                               animations:^{
                                                                                                   footerView.textLabel.enabled = YES;
                                                                                                   [self setUpdating:NO animated:NO];
                                                                                               }];
                                                                          }
                                                                          
                                                                          [self.sectionsWithActiveRequests removeIndex:section];
                                                                      }
                                                                  }];
            }
        }
    }
}

#pragma mark UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        MITNewsStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        CGFloat titleHeight = 0.;
        if ([story.title length]) {
            NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsStoriesViewController titleTextAttributes]];
            
            CGRect titleRect = [titleString boundingRectWithSize:CGSizeMake(MITNewsStoryCellMaximumTextWidth, CGFLOAT_MAX)
                                                         options:(NSStringDrawingUsesFontLeading |
                                                                  NSStringDrawingUsesLineFragmentOrigin)
                                                         context:nil];
            titleHeight = ceil(CGRectGetHeight(titleRect));
        }
        
        CGFloat dekHeight = 0.;
        if ([story.dek length]) {
            NSAttributedString *dekString = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsStoriesViewController dekTextAttributes]];
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
        return [[self.fetchedResultsController sections] count];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo numberOfObjects];
    } else {
        return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[indexPath.section];
        if (indexPath.row < [sectionInfo numberOfObjects]) {
            MITNewsStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            // TODO: Add logic to handle the StoryExternalCell.
            //  Right now there is no way to determine which cells are
            //  external so they'll just appear as StoryCells with
            //  no title, a dek and an image.
            // (2014.01.22 - bskinner)
            NSString *identifier = nil;
            if ([story.dek length]) {
                identifier = @"StoryCell";
            } else {
                identifier = @"StoryNoDekCell";
            }
            
            MITNewsStoryCell *cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
            return cell;
        } else {
            MITNewsStoryCell* cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell" forIndexPath:indexPath];
            return cell;
        }
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
    
    storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsStoriesViewController titleTextAttributes]];
    
    if ([story.dek length]) {
        storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsStoriesViewController dekTextAttributes]];
    }
    
    MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:MITNewsStoryCellDefaultImageSize];
    [storyCell.storyImageView setImageWithURL:representation.url];
}

#pragma mark UITableView Header
- (UITableViewHeaderFooterView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"LoadMoreFooter"];
    footerView.tag = NSNotFound;
    return footerView;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* headerFooterView = (UITableViewHeaderFooterView*)view;
        headerFooterView.tag = section;
        
        if (![self.sectionsWithActiveRequests containsIndex:section]) {
            UIGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadMoreStories:)];
            [headerFooterView addGestureRecognizer:gestureRecognizer];
            [self.footerGestureRecognizers setObject:gestureRecognizer forKey:view];
            headerFooterView.textLabel.enabled = YES;
        } else {
            headerFooterView.textLabel.enabled = NO;
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* headerFooterView = (UITableViewHeaderFooterView*)view;
        
        headerFooterView.tag = NSNotFound;
        
        UIGestureRecognizer* gestureRecognizer = [self.footerGestureRecognizers objectForKey:view];
        [view removeGestureRecognizer:gestureRecognizer];
        
        [self.footerGestureRecognizers removeObjectForKey:view];
    }
}

@end
