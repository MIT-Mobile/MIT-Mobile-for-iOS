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

- (NSArray *)showSearchFieldFromItems:(NSArray *)navigationBarItems
{
    NSMutableArray *rightBarItems = [navigationBarItems mutableCopy];

    NSUInteger positionOfSearchIcon = [rightBarItems indexOfObjectPassingTest:^BOOL(UIBarButtonItem *barButtonItem, NSUInteger idx, BOOL *stop) {
        if (barButtonItem.action == @selector(searchButtonWasTriggered:)) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (positionOfSearchIcon == NSNotFound) {
        return navigationBarItems;
    }
    UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.showsCancelButton = YES;
    UIView *barWrapper = [[UIView alloc]initWithFrame:searchBar.bounds];
    [barWrapper addSubview:searchBar];
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:barWrapper];
    [rightBarItems replaceObjectAtIndex:positionOfSearchIcon withObject:searchBarItem];
    [searchBar becomeFirstResponder];
    return rightBarItems;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchField];
}
@end
