#import "WorldCatHoldingsViewController.h"
#import "WorldCatBook.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

#define PADDING 10
#define CELL_LABEL_TAG 232

@implementation WorldCatHoldingsViewController

@synthesize book, holdings;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
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
    
    self.title = @"Boston Library Consortium";
    self.tableView.backgroundColor = [UIColor clearColor];
    
    if (self.book && !self.holdings) {
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSString *code = [(WorldCatHolding *)evaluatedObject code];
            return ![code isEqualToString:MITLibrariesOCLCCode];
        }];
        NSArray *tempHoldings = [[self.book.holdings allValues] filteredArrayUsingPredicate:pred];
        self.holdings = [tempHoldings sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *code1 = [(WorldCatHolding *)obj1 code];
            NSString *code2 = [(WorldCatHolding *)obj2 code];
            return [code1 compare:code2];
        }];
    }
    
    NSString *introString = [NSString stringWithFormat:@"Availability for \"%@\"", self.book.title];
    UIFont *font = [UIFont boldSystemFontOfSize:15];
    CGSize labelSize = CGSizeMake(CGRectGetWidth(self.view.bounds) - 20, 2000);
    labelSize = [introString sizeWithFont:font constrainedToSize:labelSize lineBreakMode:UILineBreakModeWordWrap];
    CGRect frame = CGRectMake(0, 0, labelSize.width + 20, labelSize.height + 20);
    UIView *headerView = [[[UIView alloc] initWithFrame:frame] autorelease];
    headerView.backgroundColor = [UIColor clearColor];
    frame = CGRectMake(10, 10, labelSize.width, labelSize.height);
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = font;
    label.text = introString;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    [headerView addSubview:label];
    self.tableView.tableHeaderView = headerView;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.holdings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    WorldCatHolding *holding = [self.holdings objectAtIndex:indexPath.row];
    cell.textLabel.text = holding.library;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WorldCatHolding *holding = [self.holdings objectAtIndex:indexPath.row];
    NSString *labelText = holding.library;
    CGSize textSize = [labelText sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]] constrainedToSize:CGSizeMake(280, 500)];
    return textSize.height + 2 * PADDING;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = @"Boston Library Consortium";
	return [UITableView groupedSectionHeaderWithTitle:headerTitle];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WorldCatHolding *holding = [self.holdings objectAtIndex:indexPath.section];
    NSURL *url = [NSURL URLWithString:holding.url];
    if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)dealloc
{
    self.book = nil;
    self.holdings = nil;
    [super dealloc];
}

@end
