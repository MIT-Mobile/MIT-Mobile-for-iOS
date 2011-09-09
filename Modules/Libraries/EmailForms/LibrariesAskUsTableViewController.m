#import "LibrariesAskUsTableViewController.h"
#import "LibrariesAskUsViewController.h"
#import "LibrariesAppointmentViewController.h"
#import "UIKit+MITAdditions.h"

#define ASK_US_ROW 0
#define APPOINTMENT_ROW 1
#define TOTAL_ROWS 2

@implementation LibrariesAskUsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView applyStandardColors];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return TOTAL_ROWS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [cell applyStandardFonts];
    }
    
    if (indexPath.row == ASK_US_ROW) {
        cell.textLabel.text = @"Ask Us!";
    } else if (indexPath.row == APPOINTMENT_ROW) {
        cell.textLabel.text = @"Make a research consultation appointment";
    }
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    UIViewController *vc = nil;
    if (indexPath.row == ASK_US_ROW) {
        vc = [[[LibrariesAskUsViewController alloc] init] autorelease];
    } else if (indexPath.row == APPOINTMENT_ROW) {
        vc = [[[LibrariesAppointmentViewController alloc] init] autorelease];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

@end
