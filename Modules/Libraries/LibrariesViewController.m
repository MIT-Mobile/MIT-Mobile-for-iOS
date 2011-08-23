#import "MITUIConstants.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesViewController.h"


#define NUMBER_OF_SECTIONS 2
#define TOP_SECTION 0
#define EXTERNAL_URLS_SECTION 1

@implementation LibrariesViewController
@synthesize searchBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
    self.searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
    self.title = @"Libraries";
    [self.tableView applyStandardColors];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - dataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TOP_SECTION:
            return 4;
            
        case EXTERNAL_URLS_SECTION:
            return 3;
            
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title;
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    title = @"Your Account";
                    break;
                case 1:
                    title = @"Locations & Hours";
                    break;
                case 2:
                    title = @"Ask Us!";
                    break;
                case 3:
                    title = @"Tell Us!";
                    break;
                    
                default:
                    break;
            }
            break;
            
        case EXTERNAL_URLS_SECTION:
            switch (indexPath.row) {
                case 0:
                    title = @"Mobile tools for library research";
                    break;
                    
                case 1:
                    title = @"MIT Libraries News";
                    break;
                    
                case 2:
                    title = @"Full MIT Libraries website";
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Libraries"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Libraries"] autorelease];
    }
    
    cell.textLabel.text = title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc;
    NSString *urlString = nil;
    
    
    switch (indexPath.section) {
        case TOP_SECTION:
            switch (indexPath.row) {
                case 0:
                    // Your Account
                    break;
                case 1:
                    // Locations and Hours
                    vc = [[[LibrariesLocationsHoursViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                case 2:
                    // Ask Us
                    break;
                case 3:
                    // Tell Us
                    break;
                    
                default:
                    break;
            }
            break;
            
        case EXTERNAL_URLS_SECTION:

            switch (indexPath.row) {
                case 0:
                    // Mobile tools
                    urlString = @"http://libguides.mit.edu/mobile";
                    break;
                    
                case 1:
                    // Mobile News
                    urlString = @"http://news-libraries.mit.edu/blog";
                    break;
                    
                case 2:
                    // Libraries Full Site
                    urlString = @"http://libraries.mit.edu";
                    break;
                    
                default:
                    break;
            }
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            break;
            
        default:
            break;
    }
    
}
@end
