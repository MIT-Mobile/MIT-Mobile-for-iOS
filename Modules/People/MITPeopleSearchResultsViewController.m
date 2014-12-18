#import "MITPeopleSearchResultsViewController.h"
#import "PersonDetails.h"

NSString * const MITDefaultHintLabelText = @"Search by name, email, or phone number. For Directory Assistance call 617-253-1000";
NSString * const MITNoResultsHintLabelText = @"No Results";

@interface MITPeopleSearchResultsViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hintLabelYConstraint;

@end

@implementation MITPeopleSearchResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self adjustTableViewInsets];
    
    // to avoid extra empty cells
    self.tableView.tableFooterView = [UIView new];
    
    // adjust hintLabel position
    self.hintLabelYConstraint.constant += [self topBarHeight];
    [self adjustHintLabelYConstraintForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setHintLabelWithText:MITDefaultHintLabelText font:[UIFont systemFontOfSize:17]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustTableViewInsets];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self adjustHintLabelYConstraintForOrientation:toInterfaceOrientation];
}

#pragma mark - getters/setters

- (void)setSearchHandler:(MITPeopleSearchHandler *)searchHandler
{
    _searchHandler = searchHandler;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

#pragma mark - UI configs

- (void) setHintLabelWithText:(NSString *)text font:(UIFont *)font
{
    [self.hintLabel setText:text];
    [self.hintLabel setFont:font];
    [self.hintLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
    [self.hintLabel setNumberOfLines:0];
    
    [self.hintLabel setHidden:NO];
}

- (void) adjustHintLabelYConstraintForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        return;
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    if( UIInterfaceOrientationIsLandscape(interfaceOrientation) )
    {
        self.hintLabelYConstraint.constant = (screenSize.width / 2) - 20;
    }
    else
    {
        self.hintLabelYConstraint.constant = (screenSize.height / 2) - 20;
    }
    
}

- (void) adjustTableViewInsets
{
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        return;
    }
    
    UIEdgeInsets insets = UIEdgeInsetsMake([self topBarHeight], 0, 0, 0);
    
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.searchHandler.searchResults count] > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchHandler.searchResults count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchResultsCell"];
    
    [cell.textLabel setFont:[UIFont systemFontOfSize:17]];
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:14]];
    
    if( indexPath.row < [self.searchHandler.searchResults count] )
    {
        PersonDetails *searchResult = self.searchHandler.searchResults[indexPath.row];
        NSString *fullname = searchResult.name;
        
        if (searchResult.title) {
            cell.detailTextLabel.text = searchResult.title;
        } else if (searchResult.dept) {
            cell.detailTextLabel.text = searchResult.dept;
        } else {
            cell.detailTextLabel.text = @" "; // if this is empty textlabel will be bottom aligned
        }
        
        // in this section we try to highlight the parts of the results that match the search terms
        cell.textLabel.attributedText = [self.searchHandler hightlightSearchTokenWithinString:fullname
                                                                             currentFont:cell.textLabel.font];
    } else {
        // Clear out the text fields in the event of cell reuse
        // Needs to be done if there is not a valid person object for this row
        // because we may be displaying an empty cell (for example, in search results
        // to suppress the "No Results" text)
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.hidden = YES;
    }
    
    return cell;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonDetails *searchResult = self.searchHandler.searchResults[indexPath.row];
    
    [self.delegate didSelectPerson:searchResult];
}

- (void) reload
{
    [self.tableView reloadData];
 
    if( [self.searchHandler.searchResults count] == 0 )
    {
        NSString *hintText;
        CGFloat fontSize;
        if( self.searchHandler.searchCancelled )
        {
            hintText = MITDefaultHintLabelText;
            fontSize = 17;
        }
        else
        {
            hintText = MITNoResultsHintLabelText;
            fontSize = 24;
        }
        
        [self setHintLabelWithText:hintText font:[UIFont systemFontOfSize:fontSize]];
        
        return;
    }
    
    [self selectFirstResult];
    [self.hintLabel setHidden:YES];
}

- (void) selectFirstResult
{
    // make sure we have at least one search result set.
    if( [self.tableView numberOfSections] < 1 || [self.tableView numberOfRowsInSection:0] < 1 )
    {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self tableView:self.tableView willSelectRowAtIndexPath:indexPath];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - helpers

- (CGFloat) topBarHeight
{
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    return CGRectGetHeight(self.navigationController.navigationBar.frame) + MIN(statusBarSize.width, statusBarSize.height);
}

- (CGFloat) landscapeHeightDelta
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    return size.height - size.width;
}

@end
