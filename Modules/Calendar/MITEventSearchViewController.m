#import "MITEventSearchViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarEventCell.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarEventDateGroupedDataSource.h"
#import "MITEventSearchTypeAheadViewController.h"
#import "MITEventSearchResultsViewController.h"

typedef NS_ENUM(NSInteger, MITEventSearchViewControllerState) {
    MITEventSearchViewControllerStateTypeAhead,
    MITEventSearchViewControllerStateResults
};

@interface MITEventSearchViewController () <UISearchBarDelegate, MITEventSearchTypeAheadViewControllerDelegate, MITEventSearchResultsViewControllerDelegate>

@property (nonatomic) MITEventSearchViewControllerState state;
@property (nonatomic, strong) MITEventSearchTypeAheadViewController *typeAheadViewController;
@property (nonatomic, strong) MITEventSearchResultsViewController *resultsViewController;
//@property (nonatomic) MITEventSearchViewControllerResultsTimeframe resultsTimeframe;
//@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *tableViewContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewContainerViewBottomLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewContainerViewTopLayoutConstraint;
@property (nonatomic, strong) UISearchBar *searchBar;
//@property (nonatomic, strong) MITCalendarEventDateGroupedDataSource *resultsDataSource;
//@property (nonatomic, strong) NSArray *typeAheadArray;

// Currently only a single MITCalendarsCalendar object. When additional filters are specified, perhaps a filter object will be useful to create
//@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
@property (nonatomic, strong) UILabel *currentCalendarLabel;
@property (nonatomic, strong) UIView *currentCalendarLabelContainerView;

@property (weak, nonatomic) UIView *navBarSeparatorView;
@property (strong, nonatomic) UIView *repositionedNavBarSeparatorView;

@end

@implementation MITEventSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)initWithCategory:(MITCalendarsCalendar *)category
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.currentCalendar = category;
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.typeAheadViewController = [[MITEventSearchTypeAheadViewController alloc] initWithNibName:nil bundle:nil];
    self.typeAheadViewController.delegate = self;
    self.typeAheadViewController.currentCalendar = self.currentCalendar;
    
    self.resultsViewController = [[MITEventSearchResultsViewController alloc] initWithNibName:nil bundle:nil];
    self.resultsViewController.delegate = self;
    self.resultsViewController.currentCalendar = self.currentCalendar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.opaque = YES;
    navigationBar.translucent = NO;
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    [navigationBar setBarTintColor:navbarGrey];
    
    [self setupSearchBar];
    self.state = MITEventSearchViewControllerStateTypeAhead;
    [self setTypeAheadViewControllerActive];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navBarSeparatorView.hidden = YES;
    [self registerForKeyboardNotifications];
    [self.typeAheadViewController updateWithTypeAheadText:self.searchBar.text];
    if (!self.searchBar.superview) {
        [self addSearchBar];
    }
    if (self.state == MITEventSearchViewControllerStateTypeAhead) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navBarSeparatorView.hidden = NO;
    [self unregisterForKeyboardNotifications];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.searchBar.frame = self.navigationController.navigationBar.bounds;
}

- (void)setupSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    self.searchBar.showsCancelButton = YES;
    self.searchBar.delegate = self;
    [self.navigationController.navigationBar addSubview:self.searchBar];
}

- (void)removeSearchBar
{
    self.searchBar.frame = self.navigationController.navigationBar.bounds;
    [self.searchBar removeFromSuperview];
}

- (void)addSearchBar
{
    [self.navigationController.navigationBar addSubview:self.searchBar];
}

- (void)addExtendedNavBar
{
    if (!self.currentCalendar) {
        return;
    }
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    
    self.currentCalendarLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -2, self.view.frame.size.width, 16)];
    self.currentCalendarLabel.text = [NSString stringWithFormat:@"In %@", self.currentCalendar.name];
    self.currentCalendarLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.currentCalendarLabel.font = [UIFont systemFontOfSize:14];
    self.currentCalendarLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.currentCalendarLabel];
    
    self.currentCalendarLabelContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, navigationBar.frame.origin.y + navigationBar.frame.size.height, self.view.frame.size.width, 20)];
    self.currentCalendarLabelContainerView.backgroundColor = navbarGrey;
    [self.currentCalendarLabelContainerView addSubview:self.currentCalendarLabel];
    [self.view addSubview:self.currentCalendarLabelContainerView];
    
    self.tableViewContainerViewTopLayoutConstraint.constant = 20;
    
    self.navBarSeparatorView = [self findHairlineImageViewUnder:navigationBar];
    self.navBarSeparatorView.hidden = YES;
    
    self.repositionedNavBarSeparatorView = [[UIImageView alloc] initWithFrame:self.navBarSeparatorView.frame];
    self.repositionedNavBarSeparatorView.backgroundColor = [UIColor colorWithRed:150.0/255.0 green:152.0/255.0 blue:156.0/255.0 alpha:1.0];
    CGRect repositionedFrame = self.repositionedNavBarSeparatorView.frame;
    repositionedFrame.origin.y = self.currentCalendarLabelContainerView.frame.size.height - self.repositionedNavBarSeparatorView.frame.size.height;
    self.repositionedNavBarSeparatorView.frame = repositionedFrame;
    self.repositionedNavBarSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.currentCalendarLabelContainerView addSubview:self.repositionedNavBarSeparatorView];
}

- (void)removeExtendedNavBar
{
    [self.currentCalendarLabelContainerView removeFromSuperview];
    self.tableViewContainerViewTopLayoutConstraint.constant = 0;
    self.navBarSeparatorView.hidden = NO;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)setCurrentCalendar:(MITCalendarsCalendar *)currentCalendar
{
    if (self.currentCalendar == currentCalendar) {
        return;
    }
    
    _currentCalendar = currentCalendar;
    self.typeAheadViewController.currentCalendar = currentCalendar;
    self.resultsViewController.currentCalendar = currentCalendar;
}

- (void)setState:(MITEventSearchViewControllerState)newState
{
    if (newState == self.state) {
        return;
    }
    
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            [self setTypeAheadViewControllerInactive];
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            [self setResultsViewControllerInactive];
            break;
        }
    }
    
    switch (newState) {
        case MITEventSearchViewControllerStateTypeAhead: {
            [self setTypeAheadViewControllerActive];
            [self removeExtendedNavBar];
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            [self setResultsViewControllerActive];
            [self addExtendedNavBar];
            break;
        }
    }
    
    _state = newState;
}

- (void)setTypeAheadViewControllerActive
{
    [self addChildViewController:self.typeAheadViewController];
    self.typeAheadViewController.view.frame = self.tableViewContainerView.bounds;
    [self.tableViewContainerView addSubview:self.typeAheadViewController.view];
    [self.typeAheadViewController didMoveToParentViewController:self];
}

- (void)setTypeAheadViewControllerInactive
{
    [self.typeAheadViewController willMoveToParentViewController:nil];
    [self.typeAheadViewController.view removeFromSuperview];
    [self.typeAheadViewController removeFromParentViewController];
}

- (void)setResultsViewControllerActive
{
    [self addChildViewController:self.resultsViewController];
    self.resultsViewController.view.frame = self.tableViewContainerView.bounds;
    [self.tableViewContainerView addSubview:self.resultsViewController.view];
    [self.resultsViewController didMoveToParentViewController:self];
}

- (void)setResultsViewControllerInactive
{
    [self.resultsViewController willMoveToParentViewController:nil];
    [self.resultsViewController.view removeFromSuperview];
    [self.resultsViewController removeFromParentViewController];
}

- (void)beginSearch:(NSString *)searchString
{
    self.searchBar.text = searchString;
    [self.searchBar resignFirstResponder];
    
    if (self.state != MITEventSearchViewControllerStateResults) {
        self.state = MITEventSearchViewControllerStateResults;
    }
    [self.resultsViewController beginSearch:searchString];
}

#pragma mark - Keyboard Height Actions

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        CGRect endFrame = [[notification.userInfo valueForKeyPath:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        // Apple doesn't give the keyboard frame in the current view's coordinate system, it gives it in the window one, so width/height can be reversed when in landscape mode.
        endFrame = [self.view convertRect:endFrame fromView:nil];
        
        self.tableViewContainerViewBottomLayoutConstraint.constant = endFrame.size.height;
        [self.view setNeedsLayout];
        [self.view updateConstraintsIfNeeded];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.tableViewContainerViewBottomLayoutConstraint.constant = 0;
        [self.view setNeedsLayout];
        [self.view updateConstraintsIfNeeded];
    }
}

#pragma mark - Filters

// Only single calendar filters for now. This will need to change when more filters are added
- (void)clearFilters
{
    self.currentCalendar = nil;
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.state != MITEventSearchViewControllerStateTypeAhead) {
        self.state = MITEventSearchViewControllerStateTypeAhead;
    }
    [self.typeAheadViewController updateWithTypeAheadText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self beginSearch:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MITEventSearchTypeAheadViewControllerDelegate Methods

- (void)eventSearchTypeAheadController:(MITEventSearchTypeAheadViewController *)typeAheadController didSelectSuggestion:(NSString *)suggestion
{
    [self beginSearch:suggestion];
}

- (void)eventSearchTypeAheadControllerDidClearFilters:(MITEventSearchTypeAheadViewController *)typeAheadController
{
    [self clearFilters];
}

#pragma mark - MITEventSearchResultsViewControllerDelegate Methods

- (void)eventSearchResultsViewController:(MITEventSearchResultsViewController *)resultsViewController didSelectEvent:(MITCalendarsEvent *)event
{
    [self removeSearchBar];
    
    MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.event = event;
    [self.navigationController pushViewController:detailVC animated:YES];
}

@end
