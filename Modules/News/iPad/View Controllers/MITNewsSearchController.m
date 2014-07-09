#import "MITNewsSearchController.h"
#import "MITNewsModelController.h"
#import "MITNewsRecentSearchController.h"
@interface MITNewsSearchController () <UISearchBarDelegate, UIPopoverControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) MITNewsRecentSearchController *recentSearchController;
@property (nonatomic, strong) UIPopoverController *recentSearchPopoverController;
@property (weak, nonatomic) IBOutlet UITableView *searchTableView;

@end

@implementation MITNewsSearchController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - properties

- (MITNewsRecentSearchController *)recentSearchController
{
    if(!_recentSearchController) {
        MITNewsRecentSearchController *recentSearchController = [[MITNewsRecentSearchController alloc] init];
        _recentSearchController = recentSearchController;
    }
    return _recentSearchController;
}

#pragma mark - View lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.view.frame = self.navigationController.view.frame;
    self.searchTableView.alpha = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SearchBar

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchField];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self hideSearchRecents];
    [self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.recentSearchController addRecentSearchItem:searchBar.text];
    [self.recentSearchPopoverController dismissPopoverAnimated:NO];
    self.searchTableView.alpha = 1;
    self.view.alpha = 1;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.recentSearchController filterResultsUsingString:searchText];
    
}

- (UISearchBar *)returnSearchBar
{
    UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.showsCancelButton = YES;
    self.searchBar = searchBar;
    return searchBar;
}

#pragma mark - hide/show Recents

- (void)hideSearchRecents
{
    if (self.recentSearchPopoverController != nil) {
        if (self.recentSearchController.confirmSheet == nil) {
            [self.recentSearchPopoverController dismissPopoverAnimated:YES];
            self.recentSearchPopoverController = nil;
        }
    }
}

- (void)showSearchRecents
{
    
    UIPopoverController *recentSearchPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.recentSearchController];
    recentSearchPopoverController.popoverContentSize = CGSizeMake(300, 350);
    
    recentSearchPopoverController.backgroundColor = [UIColor whiteColor];
    recentSearchPopoverController.delegate = self;
    
    recentSearchPopoverController.passthroughViews = @[self.searchBar];
    
    [recentSearchPopoverController presentPopoverFromRect:[self.searchBar bounds] inView:self.searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    self.recentSearchPopoverController = recentSearchPopoverController;
}

- (void)hideSearchField
{
    [self.delegate hideSearchField];
}

#pragma mark - Popover

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.recentSearchPopoverController = nil;
    [self hideSearchField];
    [self.searchBar resignFirstResponder];
}

#pragma mark - TableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

@end
