#import "MITMapBookmarksViewController.h"
#import "MITCoreDataController.h"
#import "MITMapModelController.h"
#import "MITMapBookmark.h"
#import "MITMapPlaceCell.h"

static NSString *const kAddBookmarksLabelText = @"No Bookmarks";
static NSString *const kMITMapsBookmarksTableCellIdentifier = @"kMITMapsBookmarksTableCellIdentifier";

@interface MITMapBookmarksViewController ()

@property (nonatomic, strong) NSArray *bookmarkedPlaces;
@property (nonatomic, strong) UIView *noResultsView;

@property (nonatomic, strong) UIBarButtonItem *bookmarksDoneButton;

@end

@implementation MITMapBookmarksViewController

@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.bookmarksDoneButton = self.navigationItem.rightBarButtonItem;
    
    [self setupTableView];
    [self setupNoResultsView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateBookmarkedPlaces];
    [self updateTableState];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
   // [self updateNoBookmarksLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([MITMapPlaceCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITMapsBookmarksTableCellIdentifier];
}

- (void)updateBookmarkedPlaces
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:[[MITMapModelController sharedController] bookmarkedPlaces:nil] error:&error];
    
    if (!error) {
        self.bookmarkedPlaces = fetchResults;
    }
}

- (void)updateTableState
{
    if ([self hasBookmarkedPlaces]) {
        [self showTable];
    }
    else {
        [self hideTable];
    }
}

- (BOOL)hasBookmarkedPlaces
{
    return [self.bookmarkedPlaces count] > 0;
}

- (void)showTable
{
    [self setNoResultsViewHidden:YES];
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)hideTable
{
    [self setEditing:NO animated:YES];
    [self setNoResultsViewHidden:NO];
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bookmarkedPlaces ? self.bookmarkedPlaces.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapsBookmarksTableCellIdentifier forIndexPath:indexPath];
    [cell setPlace:self.bookmarkedPlaces[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteBookmarkAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self moveBookmarkedAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlace *place = self.bookmarkedPlaces[indexPath.row];
    [self.delegate placeSelectionViewController:self didSelectPlace:place];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITMapPlaceCell heightForPlace:self.bookmarkedPlaces[indexPath.row] tableViewWidth:self.tableView.frame.size.width accessoryType:UITableViewCellAccessoryNone];
}

- (void)deleteBookmarkAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlace *place = self.bookmarkedPlaces[indexPath.row];
    [[MITMapModelController sharedController] removeBookmarkForPlace:place
                                                          completion:^(NSError *error) {
                                                              [self updateBookmarkedPlaces];
                                                              if ([self hasBookmarkedPlaces]) {
                                                                  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                              }
                                                              else {
                                                                 [self.tableView reloadData];
                                                                  [self updateTableState];
                                                              }
                                                          }];
}

- (void)moveBookmarkedAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    MITMapPlace *place = self.bookmarkedPlaces[fromIndex];
    [[MITMapModelController sharedController] moveBookmarkForPlace:place toIndex:toIndex completion:nil];
}

#pragma mark - Setters

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing
             animated:animated];
    
    if (editing) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.bookmarksDoneButton;
    }
}

#pragma mark - No Results View

- (void)setupNoResultsView
{
    UILabel *noResultsLabel = [[UILabel alloc] init];
    noResultsLabel.text = @"No Bookmarks";
    noResultsLabel.font = [UIFont systemFontOfSize:24.0];
    noResultsLabel.textColor = [UIColor grayColor];
    noResultsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *noResultsView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    [noResultsView addSubview:noResultsLabel];
    [noResultsView addConstraints:@[[NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:noResultsView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
                                    [NSLayoutConstraint constraintWithItem:noResultsLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:noResultsView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]]];
    self.noResultsView = noResultsView;
}

- (void)setNoResultsViewHidden:(BOOL)hidden
{
    self.tableView.separatorStyle = hidden ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundView = hidden ? nil : self.noResultsView;
}

@end
