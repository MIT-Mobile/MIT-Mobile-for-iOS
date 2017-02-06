#import "MITEventSearchViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarEventCell.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarEventDateGroupedDataSource.h"
#import "MITEventSearchTypeAheadViewController.h"
#import "MITEventSearchResultsViewController.h"
#import "MITExtendedNavBarView.h"
#import "UINavigationBar+ExtensionPrep.h"

typedef NS_ENUM(NSInteger, MITEventSearchViewControllerState) {
    MITEventSearchViewControllerStateTypeAhead,
    MITEventSearchViewControllerStateResults
};

@interface MITEventSearchViewController () <UISearchBarDelegate, MITEventSearchTypeAheadViewControllerDelegate, MITEventSearchResultsViewControllerDelegate>

@property (nonatomic) MITEventSearchViewControllerState state;
@property (nonatomic, strong) MITEventSearchTypeAheadViewController *typeAheadViewController;
@property (nonatomic, strong) MITEventSearchResultsViewController *resultsViewController;
@property (nonatomic, weak) IBOutlet UIView *tableViewContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewContainerViewBottomLayoutConstraint;
@property (nonatomic, strong) UISearchBar *searchBar;

// Currently only a single MITCalendarsCalendar object. When additional filters are specified, perhaps a filter object will be useful to create
//@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
@property (nonatomic, strong) IBOutlet UILabel *currentCalendarLabel;
@property (nonatomic, strong) IBOutlet MITExtendedNavBarView *currentCalendarLabelContainerView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *currentCalendarContainerTopSpaceConstraint;

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
    [self setupNavBar];
    [self setupSearchBar];
    self.state = MITEventSearchViewControllerStateTypeAhead;
    [self setTypeAheadViewControllerActive];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar removeShadow];
    [self registerForKeyboardNotifications];
    [self.typeAheadViewController updateWithTypeAheadText:self.searchBar.text];
    if (self.state == MITEventSearchViewControllerStateTypeAhead) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar restoreShadow];
    [self unregisterForKeyboardNotifications];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.searchBar.frame = self.navigationController.navigationBar.bounds;
}

- (void)setupNavBar
{
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    [self.navigationController.navigationBar prepareForExtensionWithBackgroundColor:navbarGrey];
    self.currentCalendarContainerTopSpaceConstraint.constant = -(self.currentCalendarLabelContainerView.frame.size.height);
}

- (void)setupSearchBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    [self.navigationController.navigationBar addSubview:self.searchBar];
}

- (void)addCurrentCalendarLabel
{
    if (!self.currentCalendar) {
        return;
    }
    
    self.currentCalendarLabel.text = [NSString stringWithFormat:@"In %@", self.currentCalendar.name];
    self.currentCalendarContainerTopSpaceConstraint.constant = 0;
}

- (void)removeCurrentCalendarLabel
{
    self.currentCalendarContainerTopSpaceConstraint.constant = -(self.currentCalendarLabelContainerView.frame.size.height);
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
            [self removeCurrentCalendarLabel];
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            [self setResultsViewControllerActive];
            [self addCurrentCalendarLabel];
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

- (void)cancelButtonPressed
{
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (self.state != MITEventSearchViewControllerStateTypeAhead) {
        self.state = MITEventSearchViewControllerStateTypeAhead;
    }
}

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
    MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.event = event;
    [self.navigationController pushViewController:detailVC animated:YES];
}


#pragma mark - Rotation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
