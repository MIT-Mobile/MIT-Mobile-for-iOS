#import "LibrariesHoldingsDetailViewController.h"
#import "MITUIConstants.h"

@interface LibrariesHoldingsDetailViewController ()
@property (nonatomic,retain) NSArray *holdings;
@end

@implementation LibrariesHoldingsDetailViewController
@synthesize holdings = _holdings;

- (id)initWithHoldings:(NSArray*)holdings
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.holdings = holdings;
    }
    return self;
}

- (void)dealloc
{
    self.holdings = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

- (IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    return;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.holdings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LibrariesHoldingsDetailCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *holding = [self.holdings objectAtIndex:indexPath.row];
    cell.textLabel.text = [holding objectForKey:@"call-no"];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    
    BOOL available = [[holding objectForKey:@"available"] boolValue];

    cell.detailTextLabel.text = [holding objectForKey:@"status"];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.font = (available) ?
                                 [UIFont boldSystemFontOfSize:CELL_DETAIL_FONT_SIZE] :
                                 [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
    cell.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
    return cell;
}

#pragma mark - TableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO:
    NSDictionary *holding = [self.holdings objectAtIndex:indexPath.row];
    CGSize labelSize = [[holding objectForKey:@"call-no"] sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE]
                                                     constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (CELL_HORIZONTAL_PADDING * 2.0), CGFLOAT_MAX)
                                                         lineBreakMode:UILineBreakModeWordWrap];
    
    
    BOOL available = [[holding objectForKey:@"available"] boolValue];
    NSString *detailString = [holding objectForKey:@"status"];
    UIFont *detailFont = (available) ? 
                          [UIFont boldSystemFontOfSize:CELL_DETAIL_FONT_SIZE] :
                          [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];

    CGSize detailSize = [detailString sizeWithFont:detailFont
                                 constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (CELL_HORIZONTAL_PADDING * 2.0), CGFLOAT_MAX)
                                     lineBreakMode:UILineBreakModeWordWrap];
    
    return (labelSize.height + detailSize.height + (CELL_VERTICAL_PADDING * 2.0));
}
@end
