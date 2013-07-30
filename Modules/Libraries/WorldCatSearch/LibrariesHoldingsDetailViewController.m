#import "LibrariesHoldingsDetailViewController.h"
#import "MITUIConstants.h"

@implementation LibrariesHoldingsDetailViewController
- (id)initWithHoldings:(NSArray*)holdings
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.holdings = holdings;
    }
    
    return self;
}

#pragma mark - View lifecycle

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)done:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    return;
}

- (void)setHoldings:(NSArray *)holdings
{
    if (![_holdings isEqual:holdings]) {
        _holdings = [holdings copy];
        
        [self.tableView reloadData];
    }
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *holding = self.holdings[indexPath.row];
    cell.textLabel.text = holding[@"call-no"];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
    
    BOOL available = [holding[@"available"] boolValue];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@",holding[@"collection"], holding[@"status"]];
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
    NSDictionary *holding = self.holdings[indexPath.row];
    CGSize labelSize = [holding[@"call-no"] sizeWithFont:[UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE]
                                                     constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (CELL_HORIZONTAL_PADDING * 2.0), CGFLOAT_MAX)
                                                         lineBreakMode:UILineBreakModeWordWrap];
    
    NSString *detailString = [NSString stringWithFormat:@"%@\n%@",holding[@"collection"], holding[@"status"]];
    UIFont *detailFont = ([holding[@"available"] boolValue]) ?
                          [UIFont boldSystemFontOfSize:CELL_DETAIL_FONT_SIZE] :
                          [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];

    CGSize detailSize = [detailString sizeWithFont:detailFont
                                 constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (CELL_HORIZONTAL_PADDING * 2.0), CGFLOAT_MAX)
                                     lineBreakMode:UILineBreakModeWordWrap];
    
    return (labelSize.height + detailSize.height + (CELL_VERTICAL_PADDING * 2.0));
}
@end
