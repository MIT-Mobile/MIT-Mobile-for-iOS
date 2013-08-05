#import "LibraryTextElementViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "LibraryFormElements.h"

static const NSInteger kEditViewTag = 0x70;
static const CGFloat kEditViewHeight = 24.;
static const CGFloat kEditViewMargin = 10.;
static const CGFloat kEditViewWidth = 300.;

@implementation LibraryTextElementViewController
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelTapped:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneTapped:)];
        
    // Add custom title label so that text fits to size.
    UILabel *label =  [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 200, NAVIGATION_BAR_HEIGHT - 4)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(0, -1);
    label.text = self.textElement.displayLabel;
    
    self.navigationItem.titleView = label;
    
    // Uncomment the following line to display an Edit button in the navigation 
    // bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView applyStandardColors];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // The user is here to type. Show keyboard. 
    [[self.tableView viewWithTag:kEditViewTag] becomeFirstResponder];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table view data source
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        // Set up cell background view.
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        backgroundView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView = backgroundView;
        
        if (indexPath.row == 0) {
            UITextField *editView = [[UITextField alloc] initWithFrame:CGRectMake(kEditViewMargin, kEditViewMargin, kEditViewWidth, kEditViewHeight)];
            editView.font = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE];
            editView.backgroundColor = [UIColor clearColor];
            editView.tag = kEditViewTag;
            editView.delegate = self;
            editView.keyboardAppearance = UIKeyboardAppearanceDefault;
            editView.returnKeyType = UIReturnKeyDone;            
            editView.text = [self.textElement value];
            [cell.contentView addSubview:editView];
        }
    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 2. * kEditViewMargin + kEditViewHeight;
    } else {
        return 44.;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    UITextField *editView = (UITextField *)[self.tableView viewWithTag:kEditViewTag];
    self.textElement.textValue = editView.text;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
