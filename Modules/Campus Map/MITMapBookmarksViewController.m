#import "MITMapBookmarksViewController.h"
#import "MITCoreDataController.h"
#import "MITMapModelController.h"
#import "MITMapPlace.h"

@interface MITMapBookmarksViewController ()

@property (nonatomic, strong) NSArray *bookmarks;
@property (nonatomic, strong) UIView *tableBackgroundView;

@end

@implementation MITMapBookmarksViewController

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
    [self loadBookmarks];
    [self updateTableState];
}

- (void)viewWillAppear:(BOOL)animated
{
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadBookmarks
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
    
    NSError *error;
    NSArray *fetchResults = [context executeFetchRequest:[[MITMapModelController sharedController] bookmarkedPlaces:nil] error:&error];
    
    if (!error) {
        self.bookmarks = fetchResults;
    }
}

- (void)updateTableState
{
    if (self.bookmarks.count > 0) {
        [self showTable];
    }
    else {
        [self hideTable];
    }
}

- (void)showTable
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundView = nil;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)hideTable
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundView = self.tableBackgroundView;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Getters

- (UIView *)tableBackgroundView
{
    if (!_tableBackgroundView) {
        _tableBackgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        
        UILabel *addBookmarksLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 80, 200, 200)];
        addBookmarksLabel.numberOfLines = 0;
        addBookmarksLabel.lineBreakMode = NSLineBreakByWordWrapping;
        addBookmarksLabel.font = [UIFont systemFontOfSize:14.0];
        addBookmarksLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        addBookmarksLabel.text = @"Add Bookmarks from building details screens.";
        
        [_tableBackgroundView addSubview:addBookmarksLabel];
    }
    return _tableBackgroundView;
}

@end
