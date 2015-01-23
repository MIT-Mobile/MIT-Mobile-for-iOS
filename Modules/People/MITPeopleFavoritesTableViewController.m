#import "MITPeopleFavoritesTableViewController.h"
#import "PeopleFavoriteData.h"

@interface MITPeopleFavoritesTableViewController ()

@property (nonatomic, strong) NSArray *favoritesData;

@end

@implementation MITPeopleFavoritesTableViewController

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
    
    self.preferredContentSize = CGSizeMake(280, 300);
    
    self.favoritesData = [PeopleFavoriteData retrieveFavoritePeople];
    
    self.navigationItem.title = @"Favorites";
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonTapped:)];
    self.navigationItem.rightBarButtonItem = editButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.2];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    
    [self.delegate didDismissFavoritesPopover];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) flashScrollIndicators
{
    [self.tableView flashScrollIndicators];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.favoritesData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MITPeopleFavoriteCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    [cell.textLabel setFont:[UIFont systemFontOfSize:17]];
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:14]];
    
    if( indexPath.row >= [self.favoritesData count] )
    {
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.hidden = YES;
        
        return cell;
    }
    
    PersonDetails *personDetails = self.favoritesData[indexPath.row];

    cell.textLabel.text = [personDetails valueForKey:@"name"];
    
    if (personDetails.title) {
        cell.detailTextLabel.text = personDetails.title;
    } else if (personDetails.dept) {
        cell.detailTextLabel.text = personDetails.dept;
    } else {
        cell.detailTextLabel.text = @""; // if this is empty textlabel will be bottom aligned
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PersonDetails *personDetails = self.favoritesData[indexPath.row];
    
    [self.delegate didSelectFavoritePerson:personDetails];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        PersonDetails *person = self.favoritesData[indexPath.row];
        [PeopleFavoriteData setPerson:person asFavorite:NO];
        
        NSMutableArray *favoritesTemp = [self.favoritesData mutableCopy];
        [favoritesTemp removeObjectAtIndex:indexPath.row];
        self.favoritesData = favoritesTemp;
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) editButtonTapped:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void) doneButtonTapped:(id)sender
{
    [self.tableView setEditing:NO animated:YES];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonTapped:)];
    self.navigationItem.rightBarButtonItem = editButton;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [PeopleFavoriteData movePerson:self.favoritesData[fromIndexPath.row] fromIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
