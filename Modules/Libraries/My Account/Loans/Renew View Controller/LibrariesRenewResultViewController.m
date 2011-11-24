#import "LibrariesRenewResultViewController.h"
#import "LibrariesLoanTableViewCell.h"
#import "MobileRequestOperation.h"
#import "MITTabHeaderView.h"

@interface LibrariesRenewResultViewController ()
@property (nonatomic,retain) NSArray *renewItems;
@property (nonatomic,retain) UIView *headerView;
@property (nonatomic,assign) UITableView *tableView;

- (UIView*)tableHeaderViewForWidth:(CGFloat)width;
@end

@implementation LibrariesRenewResultViewController
@synthesize renewItems = _renewItems;
@synthesize tableView = _tableView;
@synthesize headerView = _headerView;

- (id)init
{
    return [self initWithItems:nil];
}

- (id)initWithItems:(NSArray*)renewItems
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        // filter out NSNulls that might have come through the JSON parser
        NSIndexSet *validItems = [renewItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj valueForKey:@"details"] isKindOfClass:[NSDictionary class]]) {
                return YES;
            } else {
                return NO;
            }
        }];
        self.renewItems = [renewItems objectsAtIndexes:validItems];
        self.title = @"Renew";
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                target:self
                                                                                                action:@selector(done:)] autorelease];
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
        
        UIView *header = [self tableHeaderViewForWidth:CGRectGetWidth(mainFrame)];
        view.tableHeaderView = header;
        
        self.tableView = view;
        [self setView:view];
    }
}

- (UIView*)tableHeaderViewForWidth:(CGFloat)width
{
    NSUInteger failureCount = 0;
    NSUInteger successCount = 0;
    
    for (NSDictionary *result in self.renewItems)
    {
        if ([result objectForKey:@"error"])
        {
            ++failureCount;
        }
        else
        {
            ++successCount;
        }
    }
    
    
    UIView *tableHeader = [[MITTabHeaderView alloc] init];
    CGRect headerFrame = CGRectMake(0, 0, width, 10);
    UIEdgeInsets headerInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    headerFrame = UIEdgeInsetsInsetRect(headerFrame, headerInsets);
    
    CGPoint origin = headerFrame.origin;
    
    if (successCount)
    {
        UIImageView *successIcon = nil;
        UILabel *successLabel = nil;
        successIcon = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"libraries/status-ok"]] autorelease];
        successLabel = [[[UILabel alloc] init] autorelease];
        successLabel.lineBreakMode = UILineBreakModeTailTruncation;
        successLabel.text = [NSString stringWithFormat:@"%lu renewed successfully!", successCount];
        
        CGSize successSize = [successLabel.text sizeWithFont:successLabel.font
                                           constrainedToSize:CGSizeMake(CGRectGetWidth(headerFrame), CGFLOAT_MAX)
                                               lineBreakMode:successLabel.lineBreakMode];
        
        CGRect iconRect = CGRectMake(origin.x, origin.y, successIcon.image.size.width, successIcon.image.size.height);
        successIcon.frame = iconRect;
        
        CGRect labelRect = CGRectMake(origin.x + CGRectGetWidth(iconRect), origin.y, successSize.width, successSize.height);
        successLabel.frame = labelRect;
        
        [tableHeader addSubview:successIcon];
        [tableHeader addSubview:successLabel];
        
        CGFloat height = MAX(CGRectGetHeight(iconRect), CGRectGetHeight(labelRect));
        headerFrame.size.height += height;
        origin.y += height;
    }
    
    if (failureCount)
    {
        UIImageView *errorIcon = nil;
        UILabel *errorLabel = nil;
        errorIcon = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"libraries/status-error"]] autorelease];
        errorIcon.contentMode = UIViewContentModeCenter;
        errorIcon.backgroundColor = [UIColor clearColor];
        
        errorLabel = [[[UILabel alloc] init] autorelease];
        errorLabel.backgroundColor = [UIColor clearColor];
        errorLabel.lineBreakMode = UILineBreakModeTailTruncation;
        errorLabel.text = [NSString stringWithFormat:@"%lu could not be renewed.", failureCount];
        
        CGSize failureSize = [errorLabel.text sizeWithFont:errorLabel.font
                                         constrainedToSize:CGSizeMake(CGRectGetWidth(headerFrame), CGFLOAT_MAX)
                                             lineBreakMode:errorLabel.lineBreakMode];
        
        CGRect iconRect = CGRectMake(origin.x, origin.y, errorIcon.image.size.width, errorIcon.image.size.height);
        errorIcon.frame = iconRect;
        
        CGRect labelRect = CGRectMake(origin.x + CGRectGetWidth(iconRect), origin.y, failureSize.width, failureSize.height);
        errorLabel.frame = labelRect;
        
        [tableHeader addSubview:errorIcon];
        [tableHeader addSubview:errorLabel];
        headerFrame.size.height += failureSize.height;
    }
    
    headerFrame.size.height += (headerInsets.top + headerInsets.bottom);
    
    tableHeader.frame = headerFrame;
    
    return [tableHeader autorelease];
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
    
    NSDictionary *bookDetails = [self.renewItems objectAtIndex:indexPath.row];
    cell.itemDetails = [bookDetails objectForKey:@"details"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesLoanTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesLoanTableViewCell alloc] init];
    }
    
    NSDictionary *bookDetails = [self.renewItems objectAtIndex:indexPath.row];
    cell.itemDetails = [bookDetails objectForKey:@"details"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return [cell heightForContentWithWidth:kLibrariesTableCellDefaultWidth];
}

#pragma mark - Event Handlers
- (IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
