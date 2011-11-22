#import "LibraryTextElementViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

static const NSInteger kEditViewTag = 0x70;
static const CGFloat kEditViewHeight = 24.0f;
static const CGFloat kEditViewMargin = 10.0f;
static const CGFloat kEditViewWidth = 300.0f;

@implementation LibraryTextElementViewController

@synthesize textElement;

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [textElement release];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.leftBarButtonItem = 
    [[[UIBarButtonItem alloc] 
     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self 
     action:@selector(cancelTapped:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self 
     action:@selector(doneTapped:)] autorelease];
        
    // Add custom title label so that text fits to size.
    UILabel *label = 
    [[UILabel alloc] initWithFrame:
     CGRectMake(0, 2, 200, NAVIGATION_BAR_HEIGHT - 4)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(0, -1);
    label.text = placeholderText(self.textElement.displayLabel, 
                                 self.textElement.required);
    self.navigationItem.titleView = label;    
    [label release];
    // Uncomment the following line to display an Edit button in the navigation 
    // bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView applyStandardColors];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // The user is here to type. Show keyboard. 
    [[self.tableView viewWithTag:kEditViewTag] becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = 
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = 
        [[[UITableViewCell alloc] 
          initWithStyle:UITableViewCellStyleDefault 
          reuseIdentifier:CellIdentifier] autorelease];
        
        // Set up cell background view.
        UIView *backgroundView = 
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        backgroundView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView = backgroundView;
        [backgroundView release];
        
        if (indexPath.row == 0)
        {
            UITextField *editView = 
            [[UITextField alloc] initWithFrame:
             CGRectMake(kEditViewMargin, kEditViewMargin, kEditViewWidth, 
                        kEditViewHeight)];
            editView.font = 
            [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
            editView.backgroundColor = [UIColor clearColor];
            editView.tag = kEditViewTag;
            editView.delegate = self;
            editView.keyboardAppearance = UIKeyboardAppearanceDefault;
            editView.returnKeyType = UIReturnKeyDone;            
            editView.text = [self.textElement value];
            [cell.contentView addSubview:editView];
            [editView release];
        }
    }
        
    return cell;
}

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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

- (CGFloat)tableView:(UITableView *)tableView 
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        return 2 * kEditViewMargin + kEditViewHeight;
    }
    else
    {
        return 44;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row == 0) && (indexPath.section == 0))
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [[cell.contentView viewWithTag:kEditViewTag] becomeFirstResponder];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{
    [self doneTapped:nil];
    return YES;
}

#pragma mark UI actions
- (IBAction)cancelTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneTapped:(id)sender
{
    UITextField *editView = 
    (UITextField *)[self.tableView viewWithTag:kEditViewTag];
    self.textElement.textValue = editView.text;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
