#import "MITMapBookmarksViewController.h"
#import "MITCoreDataController.h"
#import "MITMapModelController.h"
#import "MITMapBookmark.h"

static NSString *const kAddBookmarksLabelText = @"No Bookmarks";
static NSString *const kMITMapsBookmarksTableCellIdentifier = @"kMITMapsBookmarksTableCellIdentifier";

@interface MITMapBookmarksViewController ()

@property (nonatomic, strong) NSArray *bookmarkedPlaces;
@property (nonatomic, strong) UIView *tableBackgroundView;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateBookmarkedPlaces];
    [self updateTableState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundView = nil;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)hideTable
{
    [self setEditing:NO animated:YES];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundView = self.tableBackgroundView;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapsBookmarksTableCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITMapsBookmarksTableCellIdentifier];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    }
   
    MITMapPlace *bookmarkedPlace = self.bookmarkedPlaces[indexPath.row];
    
    cell.textLabel.text = bookmarkedPlace.title;
    cell.detailTextLabel.text = bookmarkedPlace.subtitle;
    
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

#pragma mark - Getters

- (UIView *)tableBackgroundView
{
    if (!_tableBackgroundView) {
        _tableBackgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        CGFloat centerY = (self.view.frame.size.height / 2) - 70;
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        UILabel *addBookmarksLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, centerY, width, 200)];
        addBookmarksLabel.numberOfLines = 0;
        addBookmarksLabel.lineBreakMode = NSLineBreakByWordWrapping;
        addBookmarksLabel.textAlignment = NSTextAlignmentCenter;
        addBookmarksLabel.font = [UIFont systemFontOfSize:24.0];
        addBookmarksLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        addBookmarksLabel.text = kAddBookmarksLabelText;
        
        [_tableBackgroundView addSubview:addBookmarksLabel];
    }
    return _tableBackgroundView;
}

@end
