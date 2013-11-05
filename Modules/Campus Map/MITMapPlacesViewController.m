#import "MITMapPlacesViewController.h"

#import "MITAdditions.h"
#import "MITMapModel.h"
#import "MITConstants.h"
#import "MITUIConstants.h"
#import "MITMapDetailViewController.h"

static NSString* const MITMapCategoryViewAllText = @"View all on map";

@interface MITMapPlacesViewController ()
@property (nonatomic,strong) NSFetchRequest *fetchRequest;
@property (nonatomic,strong) void (^selectionBlock)(NSOrderedSet *mapPlaceIDs);
@end

@implementation MITMapPlacesViewController
#pragma mark - Initialization
- (instancetype)initWithPredicate:(NSPredicate*)predicate
                  sortDescriptors:(NSArray*)sortDescriptors
                        selection:(void (^)(NSOrderedSet *mapPlaces))block
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapPlaceEntityName];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = sortDescriptors;

    self = [super initWithFetchRequest:fetchRequest];
    if (self) {
        _selectionBlock = block;
    }

    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIEdgeInsets insets = UIEdgeInsetsMake(0, 8, 0, 0);
    UIImage *buttonImage =[UIImage imageNamed:@"global/action-map"];
    CGFloat buttonHeight = 24. + buttonImage.size.height;

    UIButton *showAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
    showAllButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), buttonHeight);
    showAllButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    showAllButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.95];
    showAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    showAllButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    showAllButton.contentEdgeInsets = insets;

    [showAllButton setImage:buttonImage forState:UIControlStateNormal];

    [showAllButton setTitle:MITMapCategoryViewAllText forState:UIControlStateNormal];
    [showAllButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    showAllButton.titleEdgeInsets = insets;

    [showAllButton addTarget:self
                      action:@selector(showAllPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    UIView *view = [[UIView alloc] initWithFrame:showAllButton.frame];
    [view addSubview:showAllButton];
    
    self.tableView.tableHeaderView = view;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(donePressed:)];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma  mark -
- (IBAction)showAllPressed:(UIButton*)showAllButton
{
    [self didSelectPlaces:[self.fetchedResultsController fetchedObjects]];
}

- (IBAction)donePressed:(UIBarButtonItem*)doneItem
{
    [self didSelectPlaces:nil];
}

- (void)didSelectPlaces:(NSArray*)places
{
    if (self.selectionBlock) {
        if (places) {
            NSArray *objectIDs = [NSManagedObjectContext objectIDsForManagedObjects:places];
            self.selectionBlock([NSOrderedSet orderedSetWithArray:objectIDs]);
        } else {
            self.selectionBlock(nil);
        }
    }
}

#pragma mark -
#pragma mark Table view data source
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    MITMapPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [place title];
    cell.detailTextLabel.text = [place subtitle];

    if ([UIDevice isIOS7]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
	
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

    MITMapPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self didSelectPlaces:@[place]];
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.navigationController) {
        MITMapPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
        MITMapDetailViewController *detailViewController = [[MITMapDetailViewController alloc] init];
        detailViewController.place = place;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}


@end

