#import "LibrariesHoldingsDetailViewController.h"
#import "UIKit+MITAdditions.h"

@implementation LibrariesHoldingsDetailViewController
- (id)initWithHoldings:(NSArray*)holdings
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.tableView.backgroundView = nil;
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
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    BOOL available = [holding[@"available"] boolValue];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@",holding[@"collection"], holding[@"status"]];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.font = (available) ?
                                 [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]] :
                                 [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    return cell;
}

#pragma mark - TableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO:
    NSDictionary *holding = self.holdings[indexPath.row];
    CGSize labelSize = [holding[@"call-no"] sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
                                                     constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (10.0 * 2.0), CGFLOAT_MAX)
                                                         lineBreakMode:NSLineBreakByWordWrapping];
    
    NSString *detailString = [NSString stringWithFormat:@"%@\n%@",holding[@"collection"], holding[@"status"]];
    UIFont *detailFont = ([holding[@"available"] boolValue]) ?
                          [UIFont boldSystemFontOfSize:[UIFont labelFontSize]] :
                          [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

    CGSize detailSize = [detailString sizeWithFont:detailFont
                                 constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds) - (10.0 * 2.0), CGFLOAT_MAX)
                                     lineBreakMode:NSLineBreakByWordWrapping];
    
    return (labelSize.height + detailSize.height + (11. * 2.0));
}
@end
