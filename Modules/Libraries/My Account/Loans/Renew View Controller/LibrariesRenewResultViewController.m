#import "LibrariesRenewResultViewController.h"
#import "LibrariesRenewTableViewCell.h"
#import "MobileRequestOperation.h"
#import "MITTabHeaderView.h"

@interface LibrariesRenewResultViewController ()
@property (nonatomic,retain) NSMutableIndexSet *selectedCells;
@property (nonatomic,retain) NSArray *renewItems;

@property (nonatomic,assign) UIBarButtonItem *cancelItem;
@property (nonatomic,assign) UIBarButtonItem *renewItem;

@property (nonatomic,retain) MobileRequestOperation *renewOperation;
@property (nonatomic,assign) UITableView *tableView;

- (void)showRenewResults:(NSArray*)results;
@end

@implementation LibrariesRenewResultViewController
@synthesize selectedCells = _selectedCells;
@synthesize renewItems = _renewItems;
@synthesize renewItem = _renewItem;
@synthesize renewOperation = _renewOperation;
@synthesize tableView = _tableView;
@synthesize cancelItem = _cancelItem;

- (id)init
{
    return [self initWithItems:nil];
}

- (id)initWithItems:(NSArray*)renewItems
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.renewItems = renewItems;
        self.selectedCells = [NSMutableIndexSet indexSet];
    }
    
    return self;
}

- (void)dealloc
{
    self.selectedCells = nil;
    self.renewItems = nil;
    
    [self.renewOperation cancel];
    self.renewOperation = nil;
    
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
    
    self.cancelItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(cancelRenew:)] autorelease];
    
    self.renewItem = [[[UIBarButtonItem alloc] initWithTitle:@"Renew"
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(renew:)] autorelease];
    self.renewItem.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = self.cancelItem;
    self.navigationItem.rightBarButtonItem = self.renewItem;
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

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if (cell) {
        if ([self.selectedCells containsIndex:indexPath.row])
        {
            [self.selectedCells removeIndex:indexPath.row];
            cell.selected = NO;
        }
        else
        {
            [self.selectedCells addIndex:indexPath.row];
            cell.selected = YES;
        }
    }
    
    self.renewItem.enabled = ([self.selectedCells count] > 0);
    
    return nil;
}

#pragma mark - UITableView Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.renewItems count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* CellIdentifier = @"LibariesHoldsTableViewCell";
    
    LibrariesRenewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesRenewTableViewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.itemDetails = [self.renewItems objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesRenewTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesRenewTableViewCell alloc] init];
    }
    
    cell.itemDetails = [self.renewItems objectAtIndex:indexPath.row];
    
    return [cell heightForContentWithWidth:kLibrariesTableCellDefaultWidth];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.selected = [self.selectedCells containsIndex:indexPath.row];;
}

#pragma mark - Event Handlers
- (IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelRenew:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)renew:(id)sender
{
    NSMutableArray *barcodes = [NSMutableArray array];
    
    [self.selectedCells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSDictionary *book = [self.renewItems objectAtIndex:idx];
        NSString *barcode = [book objectForKey:@"barcode"];
        if (barcode)
        {
            [barcodes addObject:barcode];
        }
        
    }];
    
    self.cancelItem.enabled = NO;
    self.renewItem.enabled = NO;
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:[barcodes componentsJoinedByString:@" "]
                                                       forKey:@"barcodes"];
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"renewBooks"
                                                                         parameters:params];
    [operation setCompleteBlock:^(MobileRequestOperation *operation, id jsonData, NSError *error) {
        if (error) 
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Renew"
                                                             message:[error localizedDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];
            [alert show];
            self.renewItem.enabled = YES;
            self.cancelItem.enabled = YES;
        }
        else
        {
            NSLog(@"Renew Selected Result:\n-----\n%@\n-----", jsonData);
            [self showRenewResults:(NSArray*)jsonData];
        }
        
        self.renewOperation = nil;
    }];
    
    self.renewOperation = operation;
    [operation start];
}

- (void)showRenewResults:(NSArray*)results
{
    NSMutableDictionary *updatedItems = [NSMutableDictionary dictionary];
    NSUInteger failureCount = 0;
    for (NSDictionary *result in results)
    {
        if ([result objectForKey:@"error"])
        {
            ++failureCount;
        }
        
        NSDictionary *details = [result objectForKey:@"details"];
        [updatedItems setObject:details
                         forKey:[details objectForKey:@"barcode"]];
        
    }
    
    NSMutableArray *renewedItems = [NSMutableArray array];
    NSMutableArray *refreshRows = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < [self.renewItems count]; ++idx)
    {
        NSDictionary *loanDetails = [self.renewItems objectAtIndex:idx];
        NSDictionary *newData = [updatedItems objectForKey:[loanDetails objectForKey:@"barcode"]];
        
        if (newData)
        {
            [refreshRows addObject:[NSIndexPath indexPathForRow:idx
                                                      inSection:0]];
            [renewedItems addObject:newData];
        }
        else
        {
            [renewedItems addObject:loanDetails];
        }
    }
    
    self.renewItems = renewedItems;
    
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setLeftBarButtonItem:nil
                                     animated:YES];
    
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(done:)] autorelease];
    [self.navigationItem setRightBarButtonItem:doneButton
                                      animated:YES];

    [self.tableView beginUpdates];
    {
        self.tableView.editing = NO;
        
        {
            MITTabHeaderView *updateHeader = [[[MITTabHeaderView alloc] init] autorelease];
            
            NSUInteger successCount = [results count] - failureCount;
            NSMutableString *resultString = [NSMutableString string];
            
            if (successCount)
            {
                [resultString appendFormat:@"%lu renewed successfully!", successCount];
            }
            
            if (failureCount)
            {
                [resultString appendFormat:@"%@%lu could not be renewed.", (successCount ? @"\n" : @""), failureCount];
            }
            
            UILabel *statusLabel = [[[UILabel alloc] init] autorelease];
            statusLabel.backgroundColor = [UIColor clearColor];
            statusLabel.text = resultString;
            
            CGFloat width = CGRectGetWidth(self.tableView.bounds);
            CGSize labelSize = [resultString sizeWithFont:statusLabel.font
                                        constrainedToSize:CGSizeMake(width - 10,CGFLOAT_MAX)
                                            lineBreakMode:statusLabel.lineBreakMode];
            
            statusLabel.frame = CGRectMake(5, 5, width - 10, labelSize.height);
            updateHeader.frame = CGRectMake(0,0,width,labelSize.height + 10);
            
            [updateHeader addSubview:statusLabel];
            self.tableView.tableHeaderView = updateHeader;
        }
    }
    
    [self.tableView reloadRowsAtIndexPaths:refreshRows
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

@end
