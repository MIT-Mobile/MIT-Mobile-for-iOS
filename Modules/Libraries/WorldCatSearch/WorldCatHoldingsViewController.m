#import "WorldCatHoldingsViewController.h"
#import "WorldCatBook.h"
#import "UIKit+MITAdditions.h"

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
    return self.holdings.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = @"Request item";
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    WorldCatHolding *holding = [self.holdings objectAtIndex:section];
    return holding.library;
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
