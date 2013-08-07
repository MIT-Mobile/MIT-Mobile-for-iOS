#import "CalendarEventsViewController.h"
#import "MITUIConstants.h"
#import "CalendarModule.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "CalendarEventMapAnnotation.h"
#import "MultiLineTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "MITEventList.h"
#import "CoreDataManager.h"
#import "MobileRequestOperation.h"
#import "MITMapAnnotationView.h"

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0

#define SEARCH_BUTTON_TAG 9144

@interface CalendarEventsViewController ()
// (bskinner - 2013.08)
// These really should be weak but the current code depends on having strong
// references and breaks badly when weak is used.
@property (nonatomic,strong) NavScrollerView *navigationScroller;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,strong) UIView *datePicker;
@property (nonatomic,strong) MITSearchDisplayController *searchController;
@property (nonatomic,strong) UIView *loadingIndicator;
@property (nonatomic,strong) EventListTableView *searchResultsTableView;
@property (nonatomic,strong) CalendarMapView *searchResultsMapView;

@property BOOL dateRangeDidChange;
@property NSInteger loadingIndicatorCount;

@property (copy) NSString *queuedButtonTitle;

- (void)returnToToday;
- (CGRect)contentFrame;

// helper methods used in reloadView
- (BOOL)canShowMap:(MITEventList *)listType;
- (void)incrementStartDate:(BOOL)forward;
- (void)showPreviousDate;
- (void)showNextDate;
- (BOOL)shouldShowDatePicker:(MITEventList *)listType;
- (void)setupDatePicker;
- (void)setupScrollButtons;

// search bar animation
- (void)showSearchBar;
- (void)hideSearchBar;

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch;
- (void)removeLoadingIndicator;

- (void)showSearchResultsMapView;
- (void)showSearchResultsTableView;

@end


@implementation CalendarEventsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_startDate = [NSDate date];
		_endDate = [NSDate date];
		
		_showScroller = YES;
        _showList = YES;
    }
    
    return self;
}

- (void)dealloc {
    self.mapView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (self.showList) {
        [self.mapView removeFromSuperview];
		self.mapView = nil;
	} else {
        [self.tableView removeFromSuperview];
		self.tableView = nil;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [MultiLineTableViewCell setNeedsRedrawing:YES];
	
	if (!self.activeEventList) {
		NSArray *lists = [[CalendarDataManager sharedManager] eventLists];
		if ([lists count]) {
			self.activeEventList = lists[0];
		} else {
			// TODO: show failure state
		}
	}
    
    NSArray *categories = [CalendarDataManager topLevelCategories];
    if ([categories count] == 0) {
        [self makeCategoriesRequest];
    }
    
    [self calendarListsLoaded]; // make sure the queued button loaded
    
	self.view.backgroundColor = [UIColor clearColor];
	
	if (self.showScroller) {
		[self.view addSubview:self.navigationScroller];
		[self.view addSubview:self.searchBar];
	}
	
	if ([self shouldShowDatePicker:self.activeEventList]) {
		[self.view addSubview:self.datePicker];
	}
	
	[self reloadView:self.activeEventList];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.tableView = nil;
    self.mapView = nil;
    self.navigationScroller = nil;
    self.datePicker = nil;
    self.category = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark View controller

- (void)loadView
{
    UIView *controllerView = [self defaultApplicationView];
    self.view = controllerView;

	self.dateRangeDidChange = YES;
	
	[CalendarDataManager sharedManager].delegate = self;
	[self setupScrollButtons];
}

- (void)setupScrollButtons {
	if (self.showScroller) {
        NavScrollerView *navigationScroller = self.navigationScroller;
        
        if (!navigationScroller) {
            navigationScroller = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
            navigationScroller.navScrollerDelegate = self;
            self.navigationScroller = navigationScroller;
        }
		
		[navigationScroller removeAllButtons];
        
		UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
		[searchButton setImage:searchImage forState:UIControlStateNormal];
        searchButton.adjustsImageWhenHighlighted = NO;
		searchButton.tag = SEARCH_BUTTON_TAG; // random number that won't conflict with event list types
        
        navigationScroller.currentXOffset += 4.0;
        [navigationScroller addButton:searchButton shouldHighlight:NO];
		
        // increase tappable area for search button
        UIControl *searchTapRegion = [[UIControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        searchTapRegion.backgroundColor = [UIColor clearColor];
        searchTapRegion.center = searchButton.center;
        [searchTapRegion addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
        
		NSArray *eventLists = [[CalendarDataManager sharedManager] eventLists];
		
		// create buttons for nav scroller view
        [eventLists enumerateObjectsUsingBlock:^(MITEventList *eventList, NSUInteger idx, BOOL *stop) {
			UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
			aButton.tag = idx;
			[aButton setTitle:eventList.title forState:UIControlStateNormal];
            [navigationScroller addButton:aButton shouldHighlight:YES];
        }];
        
        [navigationScroller setNeedsLayout];
		
        // TODO: use active category instead of always start at first tab
		UIButton *homeButton = [navigationScroller buttonWithTag:0];
		
        [navigationScroller buttonPressed:homeButton];
        searchTapRegion.tag = 8768; // all subviews of navscrollview need tag numbers that don't compete with buttons
        [navigationScroller addSubview:searchTapRegion];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// since we add our tableviews manually we also need to do this manually
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[self.searchResultsTableView deselectRowAtIndexPath:[self.searchResultsTableView indexPathForSelectedRow] animated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.childViewController) {
        [self.navigationController pushViewController:self.childViewController animated:NO];
        self.childViewController = nil;
    }
}

- (void)setEvents:(NSArray *)someEvents
{
    if (![_events isEqualToArray:someEvents]) {
        _events = [someEvents copy];
        
        // set "events" property on subviews if we're called via handleOpenUrl
        if (self.mapView) {
            self.mapView.events = self.events;
        }
        
        if ([self.tableView isKindOfClass:[EventListTableView class]]) {
            EventListTableView *eventListTableView = (EventListTableView*)self.tableView;
            eventListTableView.events = self.events;
        }
    }
}


#pragma mark Date manipulation

- (void)datePickerDateLabelTapped {
    //if (activeEventList != CalendarEventListTypeHoliday) {
	if (![self.activeEventList.listID isEqualToString:@"holidays"]) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        DatePickerViewController *dateVC = [[DatePickerViewController alloc] init];
        dateVC.delegate = self;
        dateVC.date = self.startDate;
        [appDelegate presentAppModalViewController:dateVC animated:YES];
    }
}

// date picker delegate

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller
{
    [self setupDatePicker];
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date
{
    self.startDate = date;
    self.dateRangeDidChange = YES;
    [self reloadView:self.activeEventList];
    
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)datePickerValueChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDate *oldDate = self.startDate;
    self.startDate = picker.date;
    [self setupDatePicker];
    self.startDate = oldDate;
}

- (void)returnToToday {
    self.startDate = [NSDate date];
    self.dateRangeDidChange = YES;
}

#pragma mark Redrawing logic and helper functions
- (CGRect)contentFrame {
	CGFloat yOffset = self.showScroller ? CGRectGetHeight(self.navigationScroller.frame) : 0.0;
	if ([self shouldShowDatePicker:self.activeEventList]) {
		[self setupDatePicker];
		yOffset += CGRectGetHeight(self.datePicker.frame) - 4.0; // 4.0 is height of transparent shadow under image
	} else {
        [self.datePicker removeFromSuperview];
	}
    
    CGRect controllerBounds = self.view.bounds;
    CGRect contentFrame = CGRectMake(CGRectGetMinX(controllerBounds),
                                     CGRectGetMinY(controllerBounds) + yOffset,
                                     CGRectGetWidth(controllerBounds),
                                     CGRectGetHeight(controllerBounds) - yOffset);
    
    return contentFrame;
}

- (void)reloadView:(MITEventList *)listType {

	[self.searchResultsMapView removeFromSuperview];
    self.searchResultsMapView = nil;
    
	[self.searchResultsTableView removeFromSuperview];
    self.searchResultsTableView = nil;
    
    [self.tableView removeFromSuperview];
    
	BOOL requestNeeded = NO;
	
	if (listType != self.activeEventList) {
		self.activeEventList = listType;
        [self returnToToday];
	}

	CGRect contentFrame = [self contentFrame];
	
	// see if we need a mapview
	if (![self canShowMap:self.activeEventList]) {
		self.showList = YES;
	}

	if (self.dateRangeDidChange && [self shouldShowDatePicker:self.activeEventList]) {
		requestNeeded = YES;
	}
	
	if (self.showScroller) {
		self.navigationItem.title = @"Events";
	}
    
	if ([self.activeEventList.listID isEqualToString:@"categories"]) {
        NSArray *someEvents = [CalendarDataManager eventsWithStartDate:self.startDate
                                                              listType:self.activeEventList
                                                              category:self.category.catID];
        
        if (someEvents != nil && [someEvents count]) {
            self.events = someEvents;
            requestNeeded = NO;
        }
    }
	
	if (self.showList) {
		self.tableView = nil;
		
		if ([self.activeEventList.listID isEqualToString:@"categories"]) {
			self.tableView = [[EventCategoriesTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped];
			[self.tableView applyStandardColors];
			EventCategoriesTableView *categoriesTV = (EventCategoriesTableView *)self.tableView;
			categoriesTV.delegate = categoriesTV;
			categoriesTV.dataSource = categoriesTV;
			categoriesTV.parentViewController = self;
            
            // populate (sub)categories from core data
            // if we receive nil from core data, then make a trip to the server
            NSArray *categories = nil;
            if (self.category) {
                NSMutableArray *subCategories = [[self.category.subCategories allObjects] mutableCopy];
                // sort "All" category, i.e. the category that is a subcategory of itself, to the beginning
                [subCategories removeObject:self.category];
                [subCategories insertObject:self.category atIndex:0];
                categories = subCategories;
            } else {
                categories = [CalendarDataManager topLevelCategories];
                if ([categories count] == 0) {
                    [self makeCategoriesRequest];
                }
            }
            
            categoriesTV.categories = categories;

            requestNeeded = NO;

		} else if([self.activeEventList.listID isEqualToString:@"OpenHouse"]) {
            OpenHouseTableView *openHouseTV = [[OpenHouseTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped];
            [openHouseTV applyStandardColors];
            self.tableView = openHouseTV;
            self.tableView.delegate = openHouseTV;
            self.tableView.dataSource = openHouseTV;
            openHouseTV.parentViewController = self;
            [[CalendarDataManager sharedManager] makeOpenHouseCategoriesRequest];
            NSArray *categories = [CalendarDataManager openHouseCategories];
            openHouseTV.categories = categories;
            [self.tableView reloadData];
            requestNeeded = NO;
        } else {
			self.tableView = [[EventListTableView alloc] initWithFrame:contentFrame];
			self.tableView.delegate = (EventListTableView *)self.tableView;
			self.tableView.dataSource = (EventListTableView *)self.tableView;
			((EventListTableView *)self.tableView).parentViewController = self;
            
            if (!requestNeeded) {
                if ([self.tableView isKindOfClass:[EventListTableView class]]) {
                    EventListTableView *eventListTableView = (EventListTableView*)self.tableView;
                    eventListTableView.events = self.events;
                }
                
				[self.tableView reloadData];
			}
		}
		
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[self.view addSubview:self.tableView];
		
		self.navigationItem.rightBarButtonItem = [self canShowMap:self.activeEventList]
		? [[UIBarButtonItem alloc] initWithTitle:@"Map"
											style:UIBarButtonItemStylePlain
										   target:self
										   action:@selector(mapButtonToggled)]
		: nil;

		[self.mapView removeFromSuperview];
	} else {
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"List"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(listButtonToggled)];

        if (self.mapView == nil) {
            self.mapView = [[CalendarMapView alloc] initWithFrame:contentFrame];
            self.mapView.delegate = self;
        }

        if (self.mapView.superview == nil) {
            [self.view addSubview:self.mapView];
        }

        if (!requestNeeded) {
            self.mapView.events = self.events;
        }
	}
	
	if ([self shouldShowDatePicker:self.activeEventList]) {
		[self setupDatePicker];
	}
	
	if (requestNeeded) {
		[self makeRequest];
	}
	
	self.dateRangeDidChange = NO;
}

- (void)selectScrollerButton:(NSString *)buttonTitle
{
	for (UIButton *aButton in self.navigationScroller.buttons) {
		if ([aButton.titleLabel.text isEqualToString:buttonTitle]) {
			[self.navigationScroller buttonPressed:aButton];
			return;
		}
	}
    // we haven't found the button among our titles;
    // hold on to it in case a request response comes in with new titles
    self.queuedButtonTitle = buttonTitle;
}

- (void)incrementStartDate:(BOOL)forward
{
	NSTimeInterval interval = [CalendarDataManager intervalForEventType:self.activeEventList
                                                               fromDate:self.startDate
                                                                forward:forward];
    
    NSDate *newDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:self.startDate];
    self.startDate = newDate;
    
	self.dateRangeDidChange = YES;
	[self reloadView:self.activeEventList];
}

- (void)showPreviousDate {
	[self incrementStartDate:NO];
}

- (void)showNextDate {
	[self incrementStartDate:YES];
}

- (BOOL)canShowMap:(MITEventList *)listType {
	return [[CalendarDataManager sharedManager] isDailyEvent:listType];
}

- (BOOL)shouldShowDatePicker:(MITEventList *)listType {
	return !([listType.listID isEqualToString:@"categories"] || [listType.listID isEqualToString:@"OpenHouse"]);
}

- (void)setupDatePicker
{
    NSInteger randomTag = 3289;
    
	if (!self.datePicker) {
		
		CGFloat yOffset = self.showScroller ? self.navigationScroller.frame.size.height : 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		
		self.datePicker = [[UIView alloc] initWithFrame:CGRectMake(0.0, yOffset, appFrame.size.width, 44.0)];
		UIImageView *datePickerBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.datePicker.bounds), CGRectGetHeight(self.datePicker.bounds))];
		datePickerBackground.image = [[UIImage imageNamed:@"global/subheadbar_background.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[self.datePicker addSubview:datePickerBackground];
		
		UIImage *buttonImage = [UIImage imageNamed:@"global/subheadbar_button.png"];
		
		UIButton *prevDate = [UIButton buttonWithType:UIButtonTypeCustom];
		prevDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		prevDate.center = CGPointMake(21.0, 21.0);
		[prevDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[prevDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[prevDate setImage:[UIImage imageNamed:MITImageNameLeftArrow] forState:UIControlStateNormal];	
		[prevDate addTarget:self action:@selector(showPreviousDate) forControlEvents:UIControlEventTouchUpInside];
		[self.datePicker addSubview:prevDate];
		
		UIButton *nextDate = [UIButton buttonWithType:UIButtonTypeCustom];
		nextDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		nextDate.center = CGPointMake(appFrame.size.width - 21.0, 21.0);
		[nextDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[nextDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[nextDate setImage:[UIImage imageNamed:MITImageNameRightArrow] forState:UIControlStateNormal];
		[nextDate addTarget:self action:@selector(showNextDate) forControlEvents:UIControlEventTouchUpInside];
		[self.datePicker addSubview:nextDate];
        
        UIFont *dateFont = [UIFont boldSystemFontOfSize:20.0];
        
        UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dateButton.titleLabel.font = dateFont;
        dateButton.titleLabel.textColor = [UIColor whiteColor];
        [dateButton addTarget:self action:@selector(datePickerDateLabelTapped) forControlEvents:UIControlEventTouchUpInside];
        dateButton.tag = randomTag;
        [self.datePicker addSubview:dateButton];
	}
	
	UIButton *dateButton = (UIButton *)[self.datePicker viewWithTag:randomTag];
    
    UIFont *dateFont = [UIFont boldSystemFontOfSize:20.0];
    NSString *dateText = [CalendarDataManager dateStringForEventType:self.activeEventList
                                                             forDate:self.startDate];
    CGSize textSize = [dateText sizeWithFont:dateFont];
    dateButton.frame = CGRectMake(0.0, 0.0, textSize.width, textSize.height);
    dateButton.center = CGPointMake(self.datePicker.center.x, self.datePicker.center.y - self.datePicker.bounds.origin.y);
    [dateButton setTitle:dateText
                forState:UIControlStateNormal];
    
    if (![self.datePicker isDescendantOfView:self.view]) {
        [self.view addSubview:self.datePicker];
    }
}


#pragma mark -
#pragma mark Search bar activation

- (void)showSearchBar
{
    if (!self.searchBar) {
        self.searchBar = [[UISearchBar alloc] initWithFrame:self.navigationScroller.frame];
        self.searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        self.searchBar.alpha = 0.0;
        [self.view addSubview:self.searchBar];
    }
    
    CGRect frame = CGRectMake(0.0, CGRectGetHeight(self.searchBar.frame),CGRectGetWidth(self.view.bounds),CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.searchBar.frame));
    
	if (!self.searchResultsTableView) {
		self.searchResultsTableView = [[EventListTableView alloc] initWithFrame:frame];
		self.searchResultsTableView.parentViewController = self;
		self.searchResultsTableView.delegate = self.searchResultsTableView;
		self.searchResultsTableView.dataSource = self.searchResultsTableView;
	}
	
	if (!self.searchResultsMapView) {
		self.searchResultsMapView = [[CalendarMapView alloc] initWithFrame:frame];
        self.searchResultsMapView.region = self.mapView.region;
		self.searchResultsMapView.delegate = self;
	}
    
    if (!self.searchController) {
        self.searchController = [[MITSearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        self.searchController.delegate = self;
        self.searchController.searchResultsTableView = self.searchResultsTableView;
        self.searchController.searchResultsDelegate = self.searchResultsTableView.delegate;
        self.searchController.searchResultsDataSource = self.searchResultsTableView.dataSource;
    }
    
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.searchBar.alpha = 1.0;
                     }];
    [self.searchController setActive:YES animated:YES];
}

- (void)hideSearchBar {
	if (self.searchBar) {
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.searchBar.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [self.searchBar removeFromSuperview];
                                 self.searchBar = nil;
                                 
                                 self.searchController = nil;
                                 
                                 [self.searchResultsMapView removeFromSuperview];
                                 self.searchResultsMapView = nil;
                                 
                                 [self.searchResultsTableView removeFromSuperview];
                                 self.searchResultsTableView = nil;
                             }
                         }];
	}
}

#pragma mark Search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self makeSearchRequest:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
	self.searchBar.text = [NSString string];
	[self hideSearchBar];
    
	[self reloadView:self.activeEventList];
}

#pragma mark -

- (void)showSearchResultsMapView {
	self.showList = NO;
	[self.view addSubview:self.searchResultsMapView];
	[self.searchResultsTableView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"List"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsTableView)];
}

- (void)showSearchResultsTableView {
	self.showList = YES;
	[self.view addSubview:self.searchResultsTableView];
	[self.searchResultsMapView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsMapView)];
}

#pragma mark -
#pragma mark UI Event observing

- (void)mapButtonToggled {
	self.showList = NO;
	[self reloadView:self.activeEventList];
}

- (void)listButtonToggled {
	self.showList = YES;
	[self reloadView:self.activeEventList];
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
	if (pressedButton.tag == SEARCH_BUTTON_TAG) {
		[self showSearchBar];
	} else {
        NSArray *eventLists = [[CalendarDataManager sharedManager] eventLists];
		MITEventList *eventList = eventLists[pressedButton.tag];
		[self reloadView:eventList];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.searchController setActive:YES animated:YES];
}

#pragma mark Map View Delegate
 
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view
{
	CalendarEventMapAnnotation *annotation = view.annotation;
	MITCalendarEvent *event = nil;
	CalendarMapView *calMapView = (CalendarMapView *)mapView;

	for (event in calMapView.events) {
		if ([event.eventID isEqualToNumber:annotation.event.eventID]) {
			break;
		}
	}

	if (event != nil) {
		CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] init];
		detailVC.event = event;
		[self.navigationController pushViewController:detailVC animated:YES];
	}
}

- (void)mapView:(MITMapView *)mapView annotationSelected:(id<MKAnnotation>)annotation {

}

#pragma mark Server connection methods

- (void)makeSearchRequest:(NSString *)searchTerms
{
    if (searchTerms.length) {
        self.lastSearchTerm = searchTerms;
        
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:CalendarTag
                                                                                  command:@"search"
                                                                              parameters:@{@"q":searchTerms}];
        
        request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
            if ([searchTerms isEqualToString:self.lastSearchTerm]) {
                if ([jsonResult isKindOfClass:[NSDictionary class]]) {
                        NSArray *resultEvents = jsonResult[@"events"];
                        NSString *resultSpan = jsonResult[@"span"];
                        
                        NSMutableArray *arrayForTable = [[NSMutableArray alloc] init];
                        
                        for (NSDictionary *eventDict in resultEvents) {
                            MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
                            [arrayForTable addObject:event];
                        }
                        
                        if ([resultEvents count] > 0) {
                            NSArray *eventsArray = [NSArray arrayWithArray:arrayForTable];
                            self.searchResultsMapView.events = eventsArray;
                            self.searchResultsTableView.events = eventsArray;
                            self.searchResultsTableView.searchSpan = resultSpan;
                            self.searchResultsTableView.searchResults = YES;
                            [self.searchResultsTableView reloadData];
                            
                            if (self.showList) {
                                [self showSearchResultsTableView];
                            } else {
                                [self showSearchResultsMapView];
                            }
                            
                        } else {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                                message:NSLocalizedString(@"Nothing found.", nil)
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alertView show];
                        }
                        
                } else {
                    if (error) {
                        DDLogVerbose(@"Calendar 'search' failed with error '%@'",error);
                    } else {
                        DDLogVerbose(@"Calendar 'search' failed with result type '%@'", NSStringFromClass([jsonResult class]));
                    }
                }
                
                [self removeLoadingIndicator];
            }
        };
        
        if (self.showList) {
            self.searchResultsTableView.events = nil;
            self.searchResultsTableView.searchResults = NO;
            [self.searchResultsTableView reloadData];
            [self showSearchResultsTableView];
        } else {
            self.searchResultsMapView.events = nil;
            [self showSearchResultsMapView];
        }
        
        [self addLoadingIndicatorForSearch:YES];
        
        [[MobileRequestOperation defaultQueue] addOperation:request];
    }
}

- (void)makeCategoriesRequest
{
	MITEventList *categories = [[CalendarDataManager sharedManager] eventListWithID:@"categories"];
    NSString *command = [CalendarDataManager apiCommandForEventType:categories];
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:CalendarTag command:command parameters:nil];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            
        } else {
            for (NSDictionary *catDict in jsonResult) {
                [CalendarDataManager categoryWithDict:catDict forListID:nil]; // save this to core data
                [CoreDataManager saveData];
            }
            
            if ([self.activeEventList.listID isEqualToString:@"categories"]) {
                [(EventCategoriesTableView *)self.tableView setCategories:[CalendarDataManager topLevelCategories]];
                [self.tableView reloadData];
            }
        }
        [self removeLoadingIndicator];
    };
    
    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)makeRequest
{
    MobileRequestOperation *request = nil;
    
	if ([[CalendarDataManager sharedManager] isDailyEvent:self.activeEventList]) {
		NSTimeInterval interval = [self.startDate timeIntervalSince1970];
		NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
		
		if (self.category) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            params[@"id"] = [NSString stringWithFormat:@"%d", [self.category.catID intValue]];
            params[@"start"] = timeString;
            
            if(self.category.listID) {
                params[@"type"] = self.category.listID;
            }
            
            request = [[MobileRequestOperation alloc] initWithModule:CalendarTag command:@"category" parameters:params];

		} else {
            NSDictionary *params = @{@"type" : self.activeEventList.listID,
                                     @"time" : timeString};
            NSString *command = [CalendarDataManager apiCommandForEventType:self.activeEventList];
            request = [[MobileRequestOperation alloc] initWithModule:CalendarTag command:command parameters:params];
		}
    
    } else if ([@[@"academic",@"holidays"] containsObject:self.activeEventList.listID]) {
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
		NSDateComponents *comps = [calendar components:unitFlags fromDate:self.startDate];
		NSString *month = [NSString stringWithFormat:@"%d", [comps month]];
		NSString *year = [NSString stringWithFormat:@"%d", [comps year]];

        NSDictionary *params = @{@"year" : year,
                                 @"month" : month};
        NSString *command = [CalendarDataManager apiCommandForEventType:self.activeEventList];
        request = [[MobileRequestOperation alloc] initWithModule:CalendarTag command:command parameters:params];
	} else {
        NSString *command = [CalendarDataManager apiCommandForEventType:self.activeEventList];
        request = [[MobileRequestOperation alloc] initWithModule:CalendarTag command:command parameters:nil];
	}
    
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            
        } else if ([jsonResult isKindOfClass:[NSArray class]]) {
            NSMutableArray *arrayForTable = [[NSMutableArray alloc] init];
            EventCategory *category = nil;
            
            if ([self.activeEventList.listID isEqualToString:@"Exhibits"]) {
                category = [CalendarDataManager categoryForExhibits];
            } else {
                category = self.category;
            }
            
            for (NSDictionary *eventDict in jsonResult) {
                MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
                // assign a category if we know already what it is
                if (category != nil) {
                    [event addCategoriesObject:category];
                }
                [self.activeEventList addEventsObject:event];
                [CoreDataManager saveData]; // save now to preserve many-many relationships
                [arrayForTable addObject:event];
            }
            
            self.events = arrayForTable;
            [self.tableView reloadData];
        }
        
        [self removeLoadingIndicator];
    };
	
    [self addLoadingIndicatorForSearch:NO];
    [[MobileRequestOperation defaultQueue] addOperation:request];
}

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch
{
	if (self.loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont systemFontOfSize:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = (self.showList) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] init];
		label.textColor = (self.showList) ? [UIColor colorWithWhite:0.5 alpha:1.0] : [UIColor whiteColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		CGRect frame = (self.showList) ? self.tableView.frame : CGRectMake(0, 0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2,  stringSize.height + verticalPadding * 2);
		self.loadingIndicator = [[UIView alloc] initWithFrame:frame];
        if (self.showList) {
            self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            self.loadingIndicator.backgroundColor = [UIColor whiteColor];
        }
        
		self.loadingIndicator.autoresizingMask = (self.showList) ? UIViewAutoresizingFlexibleHeight : UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.loadingIndicator.layer.cornerRadius = cornerRadius;
        self.loadingIndicator.backgroundColor = (self.showList) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.0 alpha:0.8];
		
		if (self.showList) {
			label.frame = CGRectMake(round((self.loadingIndicator.frame.size.width - stringSize.width + spinny.frame.size.width + horizontalSpacing) / 2),
									 round((self.loadingIndicator.frame.size.height - stringSize.height) / 2),
									 stringSize.width, stringSize.height + 2.0);
			spinny.frame = CGRectMake(round((self.loadingIndicator.frame.size.width - spinny.frame.size.width - stringSize.width) / 2),
									  round((self.loadingIndicator.frame.size.height - spinny.frame.size.height) / 2),
									  spinny.frame.size.width, spinny.frame.size.height);
			label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			spinny.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		} else {
			label.frame = CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0);
			spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
			self.loadingIndicator.center = self.mapView.center;
		}
		
		[self.loadingIndicator addSubview:spinny];
		[self.loadingIndicator addSubview:label];
	}
	
	self.loadingIndicatorCount++;
	DDLogVerbose(@"loading indicator count: %d", self.loadingIndicatorCount);
	if (![self.loadingIndicator isDescendantOfView:self.view]) {
		[self.view addSubview:self.loadingIndicator];
	}
}

- (void)removeLoadingIndicator
{
	self.loadingIndicatorCount--;
	DDLogVerbose(@"loading indicator count: %d", self.loadingIndicatorCount);
	if (self.loadingIndicatorCount <= 0) {
		self.loadingIndicatorCount = 0;
		[self.loadingIndicator removeFromSuperview];
		self.loadingIndicator = nil;
	}
}


#pragma mark CalendarDataManager

- (void)calendarListsLoaded {
	[self setupScrollButtons];
    if (self.queuedButtonTitle) {
        [self selectScrollerButton:self.queuedButtonTitle];
        self.queuedButtonTitle = nil;
    }
}

- (void)calendarListsFailedToLoad {
	DDLogVerbose(@"failed to load lists");
}

@end

