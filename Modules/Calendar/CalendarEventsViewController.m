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

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0

#define SEARCH_BUTTON_TAG 9144

@interface CalendarEventsViewController (Private)

- (void)returnToToday;

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
- (void)releaseSearchBar;

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch;
- (void)removeLoadingIndicator;

- (void)showSearchResultsMapView;
- (void)showSearchResultsTableView;

@end


@implementation CalendarEventsViewController

@synthesize startDate, endDate, events;
@synthesize activeEventList, showList, showScroller;
@synthesize tableView = theTableView, mapView = theMapView, category = theCategory;
@synthesize childViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		startDate = [[NSDate date] retain];
		endDate = [[NSDate date] retain];
		
		loadingIndicatorCount = 0;
		showScroller = YES;
		theCategory = nil;
        queuedButton = nil;
        showList = YES;
    }
    return self;
}

- (void)dealloc {
    
	[theTableView release];
    [queuedButton release];
    
    theMapView.delegate = nil;
	[theMapView release];
	
	[navScrollView release];
    
    [datePicker release];
	
	[events release];
	[startDate release];
	[endDate release];
	
    [childViewController release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (showList) {
		[theMapView release];
		theMapView = nil;
	} else {
		[theTableView release];
		theTableView = nil;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [MultiLineTableViewCell setNeedsRedrawing:YES];
	
	if (!activeEventList) {
		NSArray *lists = [[CalendarDataManager sharedManager] eventLists];
		if (lists.count) {
			activeEventList = [lists objectAtIndex:0];
		} else {
			// TODO: show failure state
		}
	}
    
    NSArray *categories = [CalendarDataManager topLevelCategories];
    if (categories == nil) {
        [self makeCategoriesRequest];
    }
    [self calendarListsLoaded]; // make sure the queued button loaded
    
	self.view.backgroundColor = [UIColor clearColor];
	
	if (showScroller) {
		[self.view addSubview:navScrollView];
		[self.view addSubview:theSearchBar];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self.view addSubview:datePicker];
	}
	
	[self reloadView:activeEventList];
}

- (void)viewDidUnload {
	
	[theTableView release];
    theTableView = nil;
	[theMapView release];
    theMapView = nil;
	
	[navScrollView release];
    navScrollView = nil;
    
    [datePicker release];
    datePicker = nil;
    
    self.category = nil;
    
    [super viewDidUnload];
}

#pragma mark View controller

- (void)loadView
{
	[super loadView];
	
	theTableView = nil;
	dateRangeDidChange = YES;
	requestDispatched = NO;
	
	[[CalendarDataManager sharedManager] registerDelegate:self];
	
	[self setupScrollButtons];
}

- (void)setupScrollButtons {
	if (showScroller) {
        if (!navScrollView) {
            navScrollView = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
            navScrollView.navScrollerDelegate = self;
        }
		
		[navScrollView removeAllButtons];
        
		UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
		[searchButton setImage:searchImage forState:UIControlStateNormal];
        searchButton.adjustsImageWhenHighlighted = NO;
		searchButton.tag = SEARCH_BUTTON_TAG; // random number that won't conflict with event list types
        navScrollView.currentXOffset += 4.0;
        [navScrollView addButton:searchButton shouldHighlight:NO];
		
        // increase tappable area for search button
        UIControl *searchTapRegion = [[[UIControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)] autorelease];
        searchTapRegion.backgroundColor = [UIColor clearColor];
        searchTapRegion.center = searchButton.center;
        [searchTapRegion addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
        
		NSArray *eventLists = [[CalendarDataManager sharedManager] eventLists];
		
		// create buttons for nav scroller view
		for (int i = 0; i < [eventLists count]; i++) {
			MITEventList *listType = [eventLists objectAtIndex:i];
			NSString *buttonTitle = listType.title;
			UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
			aButton.tag = i;
			[aButton setTitle:buttonTitle forState:UIControlStateNormal];
            [navScrollView addButton:aButton shouldHighlight:YES];
		}
        
        [navScrollView setNeedsLayout];
		
        // TODO: use active category instead of always start at first tab
		UIButton *homeButton = [navScrollView buttonWithTag:0];
		
        [navScrollView buttonPressed:homeButton];
        searchTapRegion.tag = 8768; // all subviews of navscrollview need tag numbers that don't compete with buttons
        [navScrollView addSubview:searchTapRegion];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// since we add our tableviews manually we also need to do this manually
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[searchResultsTableView deselectRowAtIndexPath:[searchResultsTableView indexPathForSelectedRow] animated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (childViewController) {
        [self.navigationController pushViewController:childViewController animated:NO];
        self.childViewController = nil;
    }
}

- (NSArray *)events
{
	return events;
}

- (void)setEvents:(NSArray *)someEvents
{
    if (events != someEvents) {
        [events release];
        events = [someEvents retain];
    }

    // set "events" property on subviews if we're called via handleOpenUrl
    if (self.mapView) {
        self.mapView.events = events;
    }
    if ([self.tableView isKindOfClass:[EventListTableView class]]) {
        ((EventListTableView *)self.tableView).events = events;
    }
}


#pragma mark Date manipulation

- (void)datePickerDateLabelTapped {
    //if (activeEventList != CalendarEventListTypeHoliday) {
	if (![activeEventList.listID isEqualToString:@"holidays"]) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        DatePickerViewController *dateVC = [[DatePickerViewController alloc] init];
        dateVC.delegate = self;
        dateVC.date = startDate;
        [appDelegate presentAppModalViewController:dateVC animated:YES];
        [dateVC release];
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
    dateRangeDidChange = YES;
    [self reloadView:activeEventList];
    
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)datePickerValueChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDate *oldDate = [[self.startDate retain] autorelease];
    self.startDate = picker.date;
    [self setupDatePicker];
    self.startDate = oldDate;
}

- (void)returnToToday {
    self.startDate = [NSDate date];
    dateRangeDidChange = YES;
}

#pragma mark Redrawing logic and helper functions

- (void)reloadView:(MITEventList *)listType {

	[searchResultsMapView removeFromSuperview];
    [searchResultsMapView release];
    searchResultsMapView = nil;
	[searchResultsTableView removeFromSuperview];
    [searchResultsTableView release];
    searchResultsTableView = nil;
    
    [self.tableView removeFromSuperview];
    
	BOOL requestNeeded = NO;
	
	if (listType != activeEventList) {
		activeEventList = listType;
        [self returnToToday];
	}

	CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
		yOffset += datePicker.frame.size.height - 4.0; // 4.0 is height of transparent shadow under image
	} else {
		[datePicker removeFromSuperview];
	}
	
	CGRect contentFrame = CGRectMake(0, self.view.bounds.origin.y + yOffset, 
									 self.view.bounds.size.width, 
									 self.view.bounds.size.height - yOffset);
	
	// see if we need a mapview
	if (![self canShowMap:activeEventList]) {
		showList = YES;
	} else if (self.mapView == nil) {
		self.mapView = [[[CalendarMapView alloc] initWithFrame:contentFrame] autorelease];
		self.mapView.delegate = self;
	}

	if (dateRangeDidChange && [self shouldShowDatePicker:activeEventList]) {
        [self abortEventListRequest];
		requestNeeded = YES;
	}
	
	if (showScroller) {
		self.navigationItem.title = @"Events";
	}
    
	if ([activeEventList.listID isEqualToString:@"categories"]) {
        NSArray *someEvents = [CalendarDataManager eventsWithStartDate:startDate
                                                              listType:activeEventList
                                                              category:self.category.catID];
        
        if (someEvents != nil && [someEvents count]) {
            self.events = someEvents;
            requestNeeded = NO;
        }
    }
	
	if (showList) {
		
		self.tableView = nil;
		
		if ([activeEventList.listID isEqualToString:@"categories"]) {
			self.tableView = [[[EventCategoriesTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped] autorelease];		
			[self.tableView applyStandardColors];
			EventCategoriesTableView *categoriesTV = (EventCategoriesTableView *)self.tableView;
			categoriesTV.delegate = categoriesTV;
			categoriesTV.dataSource = categoriesTV;
			categoriesTV.parentViewController = self;

            if (categoriesRequestDispatched) {
                [self addLoadingIndicatorForSearch:NO];
            } else {
                
                // populate (sub)categories from core data
                // if we receive nil from core data, then make a trip to the server
                NSArray *categories = nil;
                if (self.category) {
                    NSMutableArray *subCategories = [[[self.category.subCategories allObjects] mutableCopy] autorelease];
                    // sort "All" category, i.e. the category that is a subcategory of itself, to the beginning
                    [subCategories removeObject:self.category];
                    categories = [[NSArray arrayWithObject:self.category] arrayByAddingObjectsFromArray:subCategories];
                } else {
                    categories = [CalendarDataManager topLevelCategories];
					if (!categories) {
						[self makeCategoriesRequest];
					}
                }
                categoriesTV.categories = categories;
            }
            requestNeeded = NO;

		} else if([activeEventList.listID isEqualToString:@"OpenHouse"]) {
            OpenHouseTableView *openHouseTV = [[[OpenHouseTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped] autorelease];
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
			self.tableView = [[[EventListTableView alloc] initWithFrame:contentFrame] autorelease];
			self.tableView.delegate = (EventListTableView *)self.tableView;
			self.tableView.dataSource = (EventListTableView *)self.tableView;
			((EventListTableView *)self.tableView).parentViewController = self;
            
            if (!requestNeeded) {
				((EventListTableView *)self.tableView).events = events;
				[self.tableView reloadData];
			}
		}
		
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				
		[self.view addSubview:self.tableView];
		
		self.navigationItem.rightBarButtonItem = [self canShowMap:activeEventList]
		? [[[UIBarButtonItem alloc] initWithTitle:@"Map"
											style:UIBarButtonItemStylePlain
										   target:self
										   action:@selector(mapButtonToggled)] autorelease]
		: nil;
		
		[self.mapView removeFromSuperview];

	} else {
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																				   style:UIBarButtonItemStylePlain
																				  target:self
																				  action:@selector(listButtonToggled)] autorelease];
		
        if (!requestNeeded) {
            self.mapView.events = events;
        }

        [self.view addSubview:self.mapView];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
	}
	
	if (requestNeeded) {
		[self makeRequest];
	}
	
	dateRangeDidChange = NO;
}

- (void)selectScrollerButton:(NSString *)buttonTitle
{
	for (UIButton *aButton in navScrollView.buttons) {
		if ([aButton.titleLabel.text isEqualToString:buttonTitle]) {
			[navScrollView buttonPressed:aButton];
			return;
		}
	}
    // we haven't found the button among our titles;
    // hold on to it in case a request response comes in with new titles
    [queuedButton release];
    queuedButton = [buttonTitle retain];
}

- (void)incrementStartDate:(BOOL)forward
{
	NSTimeInterval interval = [CalendarDataManager intervalForEventType:activeEventList
															 fromDate:startDate
															  forward:forward];
    
    NSDate *newDate = [[[NSDate alloc] initWithTimeInterval:interval sinceDate:startDate] autorelease];
    self.startDate = newDate;
    
	dateRangeDidChange = YES;
	[self reloadView:activeEventList];
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
    
	if (datePicker == nil) {
		
		CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		
		datePicker = [[UIView alloc] initWithFrame:CGRectMake(0.0, yOffset, appFrame.size.width, 44.0)];
		UIImageView *datePickerBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, datePicker.frame.size.width, datePicker.frame.size.height)];
		datePickerBackground.image = [[UIImage imageNamed:@"global/subheadbar_background.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[datePicker addSubview:datePickerBackground];
		[datePickerBackground release];
		
		UIImage *buttonImage = [UIImage imageNamed:@"global/subheadbar_button.png"];
		
		UIButton *prevDate = [UIButton buttonWithType:UIButtonTypeCustom];
		prevDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		prevDate.center = CGPointMake(21.0, 21.0);
		[prevDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[prevDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[prevDate setImage:[UIImage imageNamed:MITImageNameLeftArrow] forState:UIControlStateNormal];	
		[prevDate addTarget:self action:@selector(showPreviousDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:prevDate];
		
		UIButton *nextDate = [UIButton buttonWithType:UIButtonTypeCustom];
		nextDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		nextDate.center = CGPointMake(appFrame.size.width - 21.0, 21.0);
		[nextDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[nextDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlStateHighlighted];
		[nextDate setImage:[UIImage imageNamed:MITImageNameRightArrow] forState:UIControlStateNormal];
		[nextDate addTarget:self action:@selector(showNextDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:nextDate];
        
        UIFont *dateFont = [UIFont fontWithName:BOLD_FONT size:20.0];
        
        UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dateButton.titleLabel.font = dateFont;
        dateButton.titleLabel.textColor = [UIColor whiteColor];
        [dateButton addTarget:self action:@selector(datePickerDateLabelTapped) forControlEvents:UIControlEventTouchUpInside];
        dateButton.tag = randomTag;
        [datePicker addSubview:dateButton];
	}
	
	UIButton *dateButton = (UIButton *)[datePicker viewWithTag:randomTag];
    
    UIFont *dateFont = [UIFont fontWithName:BOLD_FONT size:20.0];
    NSString *dateText = [CalendarDataManager dateStringForEventType:activeEventList forDate:startDate];
    CGSize textSize = [dateText sizeWithFont:dateFont];
    dateButton.frame = CGRectMake(0.0, 0.0, textSize.width, textSize.height);
    dateButton.center = CGPointMake(datePicker.center.x, datePicker.center.y - datePicker.frame.origin.y);
    [dateButton setTitle:dateText forState:UIControlStateNormal];
    
    if (![datePicker isDescendantOfView:self.view]) {
        [self.view addSubview:datePicker];
    }
}


#pragma mark -
#pragma mark Search bar activation

- (void)showSearchBar
{
    if (!theSearchBar) {
        theSearchBar = [[UISearchBar alloc] initWithFrame:navScrollView.frame];
        theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        theSearchBar.alpha = 0.0;
        [self.view addSubview:theSearchBar];
    }
    
    CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height);
    
	if (searchResultsTableView == nil) {
		searchResultsTableView = [[EventListTableView alloc] initWithFrame:frame];
		searchResultsTableView.parentViewController = self;
		searchResultsTableView.delegate = searchResultsTableView;
		searchResultsTableView.dataSource = searchResultsTableView;
	}
	
	if (searchResultsMapView == nil) {
		searchResultsMapView = [[CalendarMapView alloc] initWithFrame:frame];
        searchResultsMapView.region = self.mapView.region;
		searchResultsMapView.delegate = self;
	}
    
    if (searchController == nil) {
        searchController = [[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
        searchController.delegate = self;
        searchController.searchResultsTableView = searchResultsTableView;
        searchController.searchResultsDelegate = searchResultsTableView.delegate;
        searchController.searchResultsDataSource = searchResultsTableView.dataSource;
    }
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	theSearchBar.alpha = 1.0;
	[UIView commitAnimations];
    
    [searchController setActive:YES animated:YES];
}

- (void)hideSearchBar {
	if (theSearchBar) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchBar)];
		theSearchBar.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (void)releaseSearchBar {
    [theSearchBar removeFromSuperview];
    [theSearchBar release];
    theSearchBar = nil;
    
    [searchController release];
    searchController = nil;
    
	[searchResultsMapView removeFromSuperview];
    [searchResultsMapView release];
    searchResultsMapView = nil;

	[searchResultsTableView removeFromSuperview];
    [searchResultsTableView release];
    searchResultsTableView = nil;
}

#pragma mark Search delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self makeSearchRequest:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
	[self abortEventListRequest];

	theSearchBar.text = [NSString string];
	[self hideSearchBar];
    
	[self reloadView:activeEventList];
}

#pragma mark -

- (void)showSearchResultsMapView {
	showList = NO;
	[self.view addSubview:searchResultsMapView];
	[searchResultsTableView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsTableView)] autorelease];
}

- (void)showSearchResultsTableView {
	showList = YES;
	[self.view addSubview:searchResultsTableView];
	[searchResultsMapView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsMapView)] autorelease];
}

#pragma mark -
#pragma mark UI Event observing

- (void)mapButtonToggled {
	showList = NO;
	[self reloadView:activeEventList];
}

- (void)listButtonToggled {
	showList = YES;
	[self reloadView:activeEventList];
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
	if (pressedButton.tag == SEARCH_BUTTON_TAG) {
		[self showSearchBar];
	} else {
		MITEventList *eventList = [[[CalendarDataManager sharedManager] eventLists] objectAtIndex:pressedButton.tag];
		[self reloadView:eventList];
	}
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController setActive:YES animated:YES];
}

#pragma mark Map View Delegate
 
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view
{
	CalendarEventMapAnnotation *annotation = view.annotation;
	MITCalendarEvent *event = nil;
	CalendarMapView *calMapView = (CalendarMapView *)mapView;

	for (event in calMapView.events) {
		if (event.eventID == annotation.event.eventID) {
			break;
		}
	}

	if (event != nil) {
		CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] init];
		detailVC.event = event;
		[self.navigationController pushViewController:detailVC animated:YES];
		[detailVC release];
	}
}

- (void)mapView:(MITMapView *)mapView annotationSelected:(id<MKAnnotation>)annotation {

}

#pragma mark Server connection methods

- (void)abortEventListRequest
{
	if (requestDispatched) {
		[apiRequest abortRequest];
        apiRequest = nil;
		[self removeLoadingIndicator];
		requestDispatched = NO;
	}
}

- (void)makeSearchRequest:(NSString *)searchTerms
{
	[self abortEventListRequest];

	apiRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
	apiRequest.userData = CalendarEventAPISearch;
	requestDispatched = [apiRequest requestObjectFromModule:CalendarTag 
												   command:@"search" 
												parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil]];

	if (requestDispatched) {
		if (showList) {
			searchResultsTableView.events = nil;
            searchResultsTableView.isSearchResults = NO;
			[searchResultsTableView reloadData];
			[self showSearchResultsTableView];
		} else {
			searchResultsMapView.events = nil;
			[self showSearchResultsMapView];
		}
		
		[self addLoadingIndicatorForSearch:YES];
	}
}

- (void)makeCategoriesRequest
{
    if (categoriesRequestDispatched) return;
    
    if (!categoriesRequest) {
        categoriesRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
    }
    
	MITEventList *categories = [[CalendarDataManager sharedManager] eventListWithID:@"categories"];
    if ([categoriesRequest requestObjectFromModule:CalendarTag
										   command:[CalendarDataManager apiCommandForEventType:categories]
                                        parameters:nil]) {
        
		categoriesRequestDispatched = YES;
	}
}

- (void)makeRequest
{
	[self abortEventListRequest];
	
	apiRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
	apiRequest.userData = activeEventList.listID;
	
	if ([[CalendarDataManager sharedManager] isDailyEvent:activeEventList]) {
		NSTimeInterval interval = [startDate timeIntervalSince1970];
		NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
		
		if (self.category) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setObject:[NSString stringWithFormat:@"%d", [self.category.catID intValue]] forKey:@"id"];
            [params setObject:timeString forKey:@"start"];
            if(self.category.listID) {
                [params setObject:self.category.listID forKey:@"type"];
            }
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:@"category"
														 parameters:params];
		} else {
			
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarDataManager apiCommandForEventType:activeEventList]
														 parameters:[NSDictionary dictionaryWithObjectsAndKeys:
																	 activeEventList.listID, @"type",
																	 timeString, @"time", nil]];
		}
	} else if ([activeEventList.listID isEqualToString:@"academic"] || [activeEventList.listID isEqualToString:@"holidays"]) {
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
		NSDateComponents *comps = [calendar components:unitFlags fromDate:startDate];
		NSString *month = [NSString stringWithFormat:@"%d", [comps month]];
		NSString *year = [NSString stringWithFormat:@"%d", [comps year]];
		
		requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
														command:[CalendarDataManager apiCommandForEventType:activeEventList]
													 parameters:[NSDictionary dictionaryWithObjectsAndKeys:year, @"year", month, @"month", nil]];
	} else {
		requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
														command:[CalendarDataManager apiCommandForEventType:activeEventList]
													 parameters:nil];
		
	}
	
	if (requestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
}

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = (showList) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
		UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style] autorelease];
		[spinny startAnimating];
        
		UILabel *label = [[[UILabel alloc] init] autorelease];
		label.textColor = (showList) ? [UIColor colorWithWhite:0.5 alpha:1.0] : [UIColor whiteColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		CGRect frame = (showList) ? self.tableView.frame : CGRectMake(0, 0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2,  stringSize.height + verticalPadding * 2);
		loadingIndicator = [[UIView alloc] initWithFrame:frame];
		loadingIndicator.autoresizingMask = (showList) ? UIViewAutoresizingFlexibleHeight : UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        loadingIndicator.layer.cornerRadius = cornerRadius;
        loadingIndicator.backgroundColor = (showList) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.0 alpha:0.8];
		
		if (showList) {
			label.frame = CGRectMake(round((loadingIndicator.frame.size.width - stringSize.width + spinny.frame.size.width + horizontalSpacing) / 2),
									 round((loadingIndicator.frame.size.height - stringSize.height) / 2),
									 stringSize.width, stringSize.height + 2.0);
			spinny.frame = CGRectMake(round((loadingIndicator.frame.size.width - spinny.frame.size.width - stringSize.width) / 2),
									  round((loadingIndicator.frame.size.height - spinny.frame.size.height) / 2),
									  spinny.frame.size.width, spinny.frame.size.height);
			label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			spinny.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		} else {
			label.frame = CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0);
			spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
			loadingIndicator.center = self.mapView.center;
		}
		
		[loadingIndicator addSubview:spinny];
		[loadingIndicator addSubview:label];
	}
	
	loadingIndicatorCount++;
	DLog(@"loading indicator count: %d", loadingIndicatorCount);
	if (![loadingIndicator isDescendantOfView:self.view]) {
		[self.view addSubview:loadingIndicator];
	}
}

- (void)removeLoadingIndicator
{
	loadingIndicatorCount--;
	DLog(@"loading indicator count: %d", loadingIndicatorCount);
	if (loadingIndicatorCount <= 0) {
		loadingIndicatorCount = 0;
		[loadingIndicator removeFromSuperview];
		[loadingIndicator release];
		loadingIndicator = nil;
	}
}


#pragma mark CalendarDataManager

- (void)calendarListsLoaded {
	[self setupScrollButtons];
    if (queuedButton) {
        [self selectScrollerButton:queuedButton];
        [queuedButton release];
        queuedButton = nil;
    }
}

- (void)calendarListsFailedToLoad {
	DLog(@"failed to load lists");
}

#pragma mark MITMobileWebAPI

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {

	[self removeLoadingIndicator];
    
    if (request == categoriesRequest) {
        categoriesRequestDispatched = NO;
        categoriesRequest = nil;
        
        for (NSDictionary *catDict in result) {
            [CalendarDataManager categoryWithDict:catDict forListID:nil]; // save this to core data
			[CoreDataManager saveData];
        }
		
		if ([activeEventList.listID isEqualToString:@"categories"]) {
			[(EventCategoriesTableView *)self.tableView setCategories:[CalendarDataManager topLevelCategories]];
			[self.tableView reloadData];
		}

        return;
    }
    
	requestDispatched = NO;
    apiRequest = nil;
    
    if (result && [request.userData isEqualToString:CalendarEventAPISearch] && [result isKindOfClass:[NSDictionary class]]) {
		
        NSArray *resultEvents = [result objectForKey:@"events"];
        NSString *resultSpan = [result objectForKey:@"span"];
        
		NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[resultEvents count]];
		
        for (NSDictionary *eventDict in resultEvents) {
            MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
            [arrayForTable addObject:event];
        }
        
        if ([resultEvents count] > 0) {
            
            NSArray *eventsArray = [NSArray arrayWithArray:arrayForTable];
            searchResultsMapView.events = eventsArray;
            searchResultsTableView.events = eventsArray;
            searchResultsTableView.searchSpan = resultSpan;
            searchResultsTableView.isSearchResults = YES;
            [searchResultsTableView reloadData];
            
            if (showList) {
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
            [alertView release];
        }
        
    } else if (result && [result isKindOfClass:[NSArray class]]) {
		
		NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		
        EventCategory *category = nil;
		
		if ([activeEventList.listID isEqualToString:@"Exhibits"]) {
			category = [CalendarDataManager categoryForExhibits];
		} else {
            category = self.category;
        }
        
        for (NSDictionary *eventDict in result) {
            MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
            // assign a category if we know already what it is
            if (category != nil) {
				[event addCategoriesObject:category];
            }
			[activeEventList addEventsObject:event];
			[CoreDataManager saveData]; // save now to preserve many-many relationships
            [arrayForTable addObject:event];
        }
        
        self.events = [NSArray arrayWithArray:arrayForTable];
		
        [self.tableView reloadData];
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request
{
	DLog(@"request failed: %@", [[request userData] description]);
	
	[self removeLoadingIndicator];
    
    if (request == apiRequest) {
        requestDispatched = NO;
    } else {
        categoriesRequestDispatched = NO;
    }
}

- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Events";
}

@end

