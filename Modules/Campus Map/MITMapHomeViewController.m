#import "MITMapHomeViewController.h"

@interface MITMapHomeViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *bookmarksBarButton;
@property (nonatomic, strong) UIBarButtonItem *menuBarButton;
@property (nonatomic, strong) UILabel *searchResultsCountLabel;

@end

@implementation MITMapHomeViewController

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
    // Do any additional setup after loading the view from its nib.
    
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupResultsCountLabel];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.navigationItem setHidesBackButton:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods

- (void)setupNavigationBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-10, 0, 340, 44)];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search MIT Campus";
    // Insert the correct clear button image and uncomment the next line when ready
//    [searchBar setImage:[UIImage imageNamed:@""] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBarView.autoresizingMask = 0;
    self.searchBar.delegate = self;
    [searchBarView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarView;
    
    self.bookmarksBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(bookmarksButtonPressed)];
    [self.navigationItem setRightBarButtonItem:self.bookmarksBarButton];
    
    self.menuBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"global/menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:self.menuBarButton];
}

// Must be called after viewDidAppear
- (void)setupResultsCountLabel
{
    if (self.searchResultsCountLabel) {
        [self.searchResultsCountLabel removeFromSuperview];
    }
    
    for (UIView *subview in self.searchBar.subviews) {
        for (UIView *secondLevelSubview in subview.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                self.searchResultsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(searchBarTextField.frame.origin.x + searchBarTextField.frame.size.width - 80, searchBarTextField.frame.origin.y, 80, searchBarTextField.frame.size.height)];
                
                self.searchResultsCountLabel.textAlignment = NSTextAlignmentRight;
                self.searchResultsCountLabel.font = [UIFont systemFontOfSize:13];
                self.searchResultsCountLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
                [self setSearchResultsCountHidden:YES];
                
                [subview addSubview:self.searchResultsCountLabel];
                break;
            }
        }
    }
}

- (void)bookmarksButtonPressed
{
    
}

- (void)menuButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)closeSearchBar:(UISearchBar *)searchBar
{
    self.navigationItem.leftBarButtonItem = self.menuBarButton;
    self.navigationItem.rightBarButtonItem = self.bookmarksBarButton;
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)setSearchBarTextColor:(UIColor *)color
{
    // A public API would be preferable, but UIAppearance doesn't update unless you remove the view from superview and re-add, which messes with the display
    for (UIView *subview in self.searchBar.subviews) {
        for (UIView *secondLevelSubview in subview.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]]) {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.textColor = color;
                break;
            }
        }
    }
}

- (void)setSearchResultsCount:(NSInteger)count
{
    if (count == 1) {
        self.searchResultsCountLabel.text = [NSString stringWithFormat:@"1 Result"];
    } else {
        self.searchResultsCountLabel.text = [NSString stringWithFormat:@"%i Results", count];
    }
    
}

- (void)setSearchResultsCountHidden:(BOOL)hidden
{
    self.searchResultsCountLabel.hidden = hidden;
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self closeSearchBar:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
