#import "LibraryMenuElementViewController.h"


@implementation LibraryMenuElementViewController
@synthesize menuElement;

- (void)viewDidLoad {
    [super viewDidLoad];
    currentSelectedValue = self.menuElement.currentOptionIndex;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.title = self.menuElement.displayLabel;
    
    self.navigationItem.leftBarButtonItem = 
    [[[UIBarButtonItem alloc] 
     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self 
     action:@selector(cancelTapped:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self 
     action:@selector(doneTapped:)] autorelease];
}

- (void)dealloc
{
    self.menuElement = nil;
    [super dealloc];
}


#pragma mark - View lifecycle


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
    return self.menuElement.displayOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [self.menuElement.displayOptions objectAtIndex:indexPath.row];
    if (currentSelectedValue == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentSelectedValue = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    self.menuElement.currentOptionIndex = currentSelectedValue;
}

@end
