#import "MITNewsSearchController.h"

@interface MITNewsSearchController () <UISearchBarDelegate>

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

- (void)hideSearchField
{
    [self.delegate hideSearchField];
}

- (UISearchBar *)returnSearchBar
{
    UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.showsCancelButton = YES;
    return searchBar;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchField];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar
{
}

@end
