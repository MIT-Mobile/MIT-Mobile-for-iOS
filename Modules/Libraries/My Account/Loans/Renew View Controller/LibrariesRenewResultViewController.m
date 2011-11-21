#import "LibrariesRenewResultViewController.h"
#import "LibrariesLoanTableViewCell.h"
#import "MobileRequestOperation.h"
#import "MITTabHeaderView.h"

@interface LibrariesRenewResultViewController ()
@property (nonatomic,retain) NSArray *renewItems;

@property (nonatomic,assign) UITableView *tableView;

@end

@implementation LibrariesRenewResultViewController
@synthesize renewItems = _renewItems;
@synthesize tableView = _tableView;

- (id)init
{
    return [self initWithItems:nil];
}

- (id)initWithItems:(NSArray*)renewItems
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.renewItems = renewItems;
    }
    
    return self;
}

- (void)dealloc
{
    self.renewItems = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController.toolbarHidden == NO) 
    {
        mainFrame.origin.y += CGRectGetHeight(self.navigationController.toolbar.frame);
    }
    
    {
        UITableView *view = [[[UITableView alloc] initWithFrame:mainFrame
                                                          style:UITableViewStylePlain] autorelease];
        view.delegate = self;
        view.dataSource = self;
        view.allowsSelectionDuringEditing = YES;
        view.allowsSelection = YES;
        view.editing = YES;
        
        self.tableView = view;
        [self setView:view];
    }
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
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

#pragma mark - UITableView Delegate
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

#pragma mark - UITableView Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.renewItems count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* CellIdentifier = @"LibariesHoldsTableViewCell";
    
    LibrariesLoanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesLoanTableViewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.itemDetails = [self.renewItems objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesLoanTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesLoanTableViewCell alloc] init];
    }
    
    cell.itemDetails = [self.renewItems objectAtIndex:indexPath.row];
    
    return [cell heightForContentWithWidth:kLibrariesTableCellDefaultWidth];
}

#pragma mark - Event Handlers
- (IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
