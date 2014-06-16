//
//  PeopleSearchResultsViewController.m
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import "MITPeopleSearchResultsViewController.h"
#import "PersonDetails.h"

@interface MITPeopleSearchResultsViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didMoveToParentViewController:(UIViewController *)parent
{
    if( parent )
    {
        CGFloat top = parent.topLayoutGuide.length;
        CGFloat bottom = parent.bottomLayoutGuide.length;
        
        if( self.tableView.contentInset.top != top )
        {
            UIEdgeInsets newInsets = UIEdgeInsetsMake(top, 0, bottom, 0);
            self.tableView.contentInset = newInsets;
            self.tableView.scrollIndicatorInsets = newInsets;
        }
    }
    
    [self adjustViewHeight];
    
    [super didMoveToParentViewController:parent];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustViewHeight];
}

- (void) adjustViewHeight
{
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x,
                                      self.tableView.frame.origin.y,
                                      self.tableView.frame.size.width,
                                      self.parentViewController.view.frame.size.height);
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchResultsCell"];
    
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonDetails *searchResult = self.searchHandler.searchResults[indexPath.row];
    
    [self.delegate didSelectPerson:searchResult];
}

- (void) reload
{
    [self.tableView reloadData];
}

- (void) selectFirstResult
{
    // make sure we have at least one search result set.
    if( [self.tableView numberOfSections] < 1 || [self.tableView numberOfRowsInSection:0] < 1 )
    {
        return;
    }
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
