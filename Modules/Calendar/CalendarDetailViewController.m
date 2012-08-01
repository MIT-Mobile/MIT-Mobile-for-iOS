#import "CalendarDetailViewController.h"
#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "URLShortener.h"
#import "CalendarDataManager.h"
#import <EventKit/EventKit.h>

#define WEB_VIEW_PADDING 10.0
#define BUTTON_PADDING 10.0
#define kCategoriesWebViewTag 521
#define kDescriptionWebViewTag 516

@implementation CalendarDetailViewController

@synthesize event, events, tableView = _tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.shareDelegate = self;
	
	// setup table view
	self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)
												  style:UITableViewStylePlain] autorelease];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	[self.view addSubview:_tableView];
	
	// setup nav bar
	if (self.events.count > 1) {
		eventPager = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                [UIImage imageNamed:MITImageNameUpArrow],
                                                                [UIImage imageNamed:MITImageNameDownArrow], nil]];
		[eventPager setMomentary:YES];
		[eventPager addTarget:self action:@selector(showNextEvent:) forControlEvents:UIControlEventValueChanged];
		eventPager.segmentedControlStyle = UISegmentedControlStyleBar;
		eventPager.frame = CGRectMake(0, 0, 80.0, eventPager.frame.size.height);
		
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:eventPager];
		self.navigationItem.rightBarButtonItem = segmentBarItem;
		[segmentBarItem release];
	}
    
	descriptionString = nil;
    categoriesString = nil;
	
	// set up table rows
	[self reloadEvent];
    if ([self.event hasMoreDetails] && [self.event.summary length] == 0) {
        [self requestEventDetails];
    }
	
	descriptionHeight = 0;
}

- (void)showNextEvent:(id)sender
{
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        NSInteger i = eventPager.selectedSegmentIndex;
		NSInteger currentEventIndex = [self.events indexOfObject:self.event];
		if (i == 0) { // previous
            if (currentEventIndex > 0) {
                currentEventIndex--;
            }
		} else {
            NSInteger maxIndex = [self.events count] - 1;
            if (currentEventIndex < maxIndex) {
                currentEventIndex++;
            }
		}
		self.event = [self.events objectAtIndex:currentEventIndex];
		[self reloadEvent];
        if ([self.event hasMoreDetails] && [self.event.summary length] == 0) {
            [self requestEventDetails];
        }
    }
}

- (void)requestEventDetails
{
    if (isLoading) {
        [apiRequest abortRequest];
        isLoading = NO;
    }
    
	apiRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
	NSString *eventID = [NSString stringWithFormat:@"%d", [self.event.eventID intValue]];
	
	[apiRequest requestObjectFromModule:@"calendar" 
								command:@"detail" 
							 parameters:[NSDictionary dictionaryWithObjectsAndKeys:eventID, @"id", nil]];
    isLoading = YES;
}

- (void)reloadEvent
{
    if (event.url) {
        [self setupShareButton];
	}
	
	[self setupHeader];
    
    if ([self.events count] > 1) {
        NSInteger currentEventIndex = [self.events indexOfObject:self.event];
        [eventPager setEnabled:(currentEventIndex > 0) forSegmentAtIndex:0];
        [eventPager setEnabled:(currentEventIndex < [self.events count] - 1) forSegmentAtIndex:1];
    }
	
	if (numRows > 0) {
		free(rowTypes);
	}
	
	rowTypes = malloc(sizeof(CalendarDetailRowType) * 5);
	numRows = 0;
	if (self.event.start) {
		rowTypes[numRows] = CalendarDetailRowTypeTime;
		numRows++;
	}
	if (self.event.shortloc || self.event.location) {
		rowTypes[numRows] = CalendarDetailRowTypeLocation;
		numRows++;
	}
	if (self.event.phone) {
		rowTypes[numRows] = CalendarDetailRowTypePhone;
		numRows++;
	}
	if (self.event.url) {
		rowTypes[numRows] = CalendarDetailRowTypeURL;
		numRows++;
	}
	if (self.event.summary.length) {
		rowTypes[numRows] = CalendarDetailRowTypeDescription;
        [descriptionString release];
        descriptionString = [[self htmlStringFromString:self.event.summary] retain];
		numRows++;
	}
	if ([self.event.categories count] > 0) {
        rowTypes[numRows] = CalendarDetailRowTypeCategories;
        
        [categoriesString release];
        
        NSMutableString *categoriesBody = [NSMutableString stringWithString:@"Categorized as:<ul>"];
        for (EventCategory *category in event.categories) {
            NSString *catIDString = [NSString stringWithFormat:@"catID=%d", [category.catID intValue]];
            if(category.listID) {
                catIDString = [catIDString stringByAppendingFormat:@"&listID=%@", category.listID];
            }
            NSURL *categoryURL = [NSURL internalURLWithModuleTag:CalendarTag path:CalendarStateCategoryEventList query:catIDString];
            [categoriesBody appendString:[NSString stringWithFormat:
                                          @"<li><a href=\"%@\">%@</a></li>", [categoryURL absoluteString], category.title]];
        }
        
        [categoriesBody appendString:@"</ul>"];
        categoriesString = [[self htmlStringFromString:categoriesBody] retain];
        
        UIFont *cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
        CGSize textSize = [CalendarTag sizeWithFont:cellFont];
        // one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
        categoriesHeight = (textSize.height + 5.0) * ([event.categories count] + 2);

        numRows++;
	}
	
	[self.tableView reloadData];
}

- (void)setupShareButton {
    if (!shareButton) {
        CGRect tableFrame = self.tableView.frame;
        shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *buttonImage = [UIImage imageNamed:@"global/share.png"];
        shareButton.frame = CGRectMake(tableFrame.size.width - buttonImage.size.width - BUTTON_PADDING,
                                       BUTTON_PADDING,
                                       buttonImage.size.width,
                                       buttonImage.size.height);
        [shareButton setImage:buttonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageNamed:@"global/share_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupHeader {	
	CGRect tableFrame = self.tableView.frame;
	
	CGFloat titlePadding = 10.0;
    CGFloat titleWidth;
    if ([self.event hasMoreDetails]) {
        titleWidth = tableFrame.size.width - shareButton.frame.size.width - BUTTON_PADDING * 2 - titlePadding;
        self.tableView.separatorColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    } else {
        titleWidth = tableFrame.size.width - titlePadding * 2;
        self.tableView.separatorColor = [UIColor whiteColor];
    }
	UIFont *titleFont = [UIFont fontWithName:BOLD_FONT size:20.0];
	CGSize titleSize = [self.event.title sizeWithFont:titleFont
									constrainedToSize:CGSizeMake(titleWidth, 2010.0)];
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titlePadding, titleSize.width, titleSize.height)];
	titleView.lineBreakMode = UILineBreakModeWordWrap;
	titleView.numberOfLines = 0;
	titleView.font = titleFont;
	titleView.text = self.event.title;
	
	// if title is very short, add extra padding so button won't be too close to first cell
	if (titleSize.height < shareButton.frame.size.height) {
		titleSize.height += BUTTON_PADDING;
	}
	
	CGRect titleFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
	self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:titleFrame] autorelease];
	[self.tableView.tableHeaderView addSubview:titleView];
    if ([self.event hasMoreDetails]) {
        [self.tableView.tableHeaderView addSubview:shareButton];
    }
    
    // Add border "between" header and first cell.
    if ([self.event hasMoreDetails]) {
        UIView *bottomBorder = 
        [[UIView alloc] initWithFrame:
         CGRectMake(0, 
                    self.tableView.tableHeaderView.frame.size.height - 1, 
                    self.tableView.tableHeaderView.frame.size.width, 
                    1)];
        bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [self.tableView.tableHeaderView addSubview:bottomBorder];
        [bottomBorder release];
    }
    
	[titleView release];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)setEvent:(MITCalendarEvent *)anEvent {
	if (anEvent != event) {
        [event release];
        event = [anEvent retain];
    }
    
    [descriptionString release];
    [categoriesString release];

    descriptionString = nil;
    categoriesString = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return numRows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger rowType = rowTypes[indexPath.row];
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", rowType];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        if (rowType == CalendarDetailRowTypeCategories || rowType == CalendarDetailRowTypeDescription) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
    }
    
	[cell applyStandardFonts];
	
	switch (rowType) {
		case CalendarDetailRowTypeTime:
			cell.textLabel.text = 
            [event dateStringWithDateStyle:NSDateFormatterFullStyle 
                                 timeStyle:NSDateFormatterShortStyle 
                                 separator:@"\n"];
            cell.accessoryView = 
            [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
			break;
		case CalendarDetailRowTypeLocation:
			cell.textLabel.text = (event.location != nil) ? event.location : event.shortloc;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
			if (![event hasCoords]) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.accessoryView.hidden = YES;
            }
			break;
		case CalendarDetailRowTypePhone:
			cell.textLabel.text = event.phone;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];			
			break;
		case CalendarDetailRowTypeURL:
			cell.textLabel.text = event.url;
			cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			break;
		case CalendarDetailRowTypeDescription:
        {
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kDescriptionWebViewTag];
			webView.delegate = self;
			CGFloat webViewHeight;
			if (descriptionHeight > 0) {
				webViewHeight = descriptionHeight;
			} else {
				webViewHeight = 2000;
			}

            CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, webViewHeight);
            if (!webView) {
                webView = [[UIWebView alloc] initWithFrame:frame];
				
				// prevent webView from scrolling separately from the parent scrollview
				for (id subview in webView.subviews) {
					if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
						((UIScrollView *)subview).bounces = NO;
					}
				}
				
                webView.delegate = self;
                [webView loadHTMLString:descriptionString baseURL:nil];
                webView.tag = kDescriptionWebViewTag;
                [cell.contentView addSubview:webView];
                [webView release];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:descriptionString baseURL:nil];
            }
					
			break;
        }
		case CalendarDetailRowTypeCategories:
        {
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kCategoriesWebViewTag];
            CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, categoriesHeight);
            if (!webView) {
                webView = [[UIWebView alloc] initWithFrame:frame];
				
				// prevent webView from scrolling separately from the parent scrollview
				for (id subview in webView.subviews) {
					if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
						((UIScrollView *)subview).bounces = NO;
					}
				}
				
                [webView loadHTMLString:categoriesString baseURL:nil];
                webView.tag = kCategoriesWebViewTag;
                [cell.contentView addSubview:webView];
                [webView release];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:categoriesString baseURL:nil];
            }

			break;
        }
	}
	
    return cell;
}

- (NSString *)htmlStringFromString:(NSString *)source {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:@"calendar/events_template.html" relativeToURL:baseURL];
	NSError *error;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		ELog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}

    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING];
    [target replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, target.length)];
    
	[target replaceOccurrencesOfStrings:[NSArray arrayWithObject:@"__BODY__"] 
							withStrings:[NSArray arrayWithObject:source] 
								options:NSLiteralSearch];

	return [NSString stringWithString:target];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger rowType = rowTypes[indexPath.row];
	
	NSString *cellText = nil;
	UIFont *cellFont = nil;
	CGFloat constraintWidth;

	switch (rowType) {
		case CalendarDetailRowTypeCategories:
			return categoriesHeight;

		case CalendarDetailRowTypeTime:
			cellText = [event dateStringWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle separator:@"\n"];
			cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
			constraintWidth = tableView.frame.size.width - 21.0;
			break;
		case CalendarDetailRowTypeDescription:
			// this is the same font defined in the html template
			if(descriptionHeight > 0) {
				return descriptionHeight + CELL_VERTICAL_PADDING * 2;
			} else {
				return 400.0;
			}

			break;
		case CalendarDetailRowTypeURL:
			cellText = event.url;
			cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			// 33 and 21 are from MultiLineTableViewCell.m
			constraintWidth = tableView.frame.size.width - 33.0 - 21.0;
			break;
		case CalendarDetailRowTypeLocation:
			cellText = (event.location != nil) ? event.location : event.shortloc;
			cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
			// 33 and 21 are from MultiLineTableViewCell.m
			constraintWidth = tableView.frame.size.width - 33.0 - 21.0;
			break;
		default:
			return 44.0;
	}

	CGSize textSize = [cellText sizeWithFont:cellFont
						   constrainedToSize:CGSizeMake(constraintWidth, 2010.0)
							   lineBreakMode:UILineBreakModeWordWrap];
	
	// constant defined in MultiLineTableViewcell.h
	return textSize.height + CELL_VERTICAL_PADDING * 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSInteger rowType = rowTypes[indexPath.row];
	
	switch (rowType) {
        case CalendarDetailRowTypeTime:
        {
            EKEventStore *eventStore = [[EKEventStore alloc] init];            
            NSAutoreleasePool *eventAddPool = [[NSAutoreleasePool alloc] init];
            
            EKEvent *newEvent = [EKEvent eventWithEventStore:eventStore];
            newEvent.calendar = [eventStore defaultCalendarForNewEvents];
            [self.event setUpEKEvent:newEvent];
            
            NSInteger rowCount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
            NSInteger likelyIndexOfDescriptionRow = rowCount - 2;
            NSIndexPath *descriptionIndexPath = [NSIndexPath indexPathForRow:likelyIndexOfDescriptionRow inSection:indexPath.section];
            if (descriptionIndexPath.row > 0) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:descriptionIndexPath];
                UIWebView *webView = (UIWebView *)[cell viewWithTag:kDescriptionWebViewTag];
                NSString *result = [webView stringByEvaluatingJavaScriptFromString:
                                    @"function f(){ return document.body.innerText; } f();"];
                if (result) {
                    newEvent.notes = result;
                }
            }
            
            EKEventEditViewController *eventViewController = 
            [[EKEventEditViewController alloc] init];
            eventViewController.event = newEvent;
            eventViewController.eventStore = eventStore;
            eventViewController.editViewDelegate = self;
            [self presentModalViewController:eventViewController animated:YES];
            
            [eventAddPool release];            
            [eventStore release];
            break;
        }
		case CalendarDetailRowTypeLocation:
            if ([event hasCoords]) {
                [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:event.shortloc]];
            }
			break;
		case CalendarDetailRowTypePhone:
		{
			NSString *phoneString = [event.phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
			break;
		}
		case CalendarDetailRowTypeURL:
		{
			NSURL *eventURL = [NSURL URLWithString:event.url];
			if (event.url && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			break;
		}
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark ShareItemDelegate

- (NSString *)actionSheetTitle {
	return @"Share this event";
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"MIT Event: %@", event.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n\n%@\n\n%@", event.summary, event.url];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
	return [NSString stringWithFormat:
			@"{\"name\":\"%@\","
			"\"href\":\"%@\","
			"\"description\":\"%@\""
			"}",
			[event.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
            event.url,
            [event.summary stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
}

- (NSString *)twitterUrl {
    return event.url;
	//return [NSString stringWithFormat:@"http://%@/e/%@", MITMobileWebDomainString, [URLShortener compressedIdFromNumber:event.eventID]];
}

- (NSString *)twitterTitle {
	return event.title;
}

#pragma mark JSONLoadedDelegate for background refreshing of events

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)result {
    isLoading = NO;
	if (result && [result isKindOfClass:[NSDictionary class]]) {
        // make sure the event that the server returns is the one being viewed
        if ([[result objectForKey:@"id"] intValue] == [self.event.eventID intValue]) {
            [self.event updateWithDict:result];
            [self reloadEvent];
        }
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    isLoading = NO;
	return NO;
}

- (void)dealloc {
    if (isLoading) {
        [apiRequest abortRequest];
    }
    
    self.event = nil;
    self.events = nil;
	free(rowTypes);

    [eventPager release];
	[shareButton release];
    [categoriesString release];
    [descriptionString release];
    [_tableView release];
    [super dealloc];
}


#pragma mark -
#pragma mark UIWebView delegation

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// calculate webView height, if it change we need to reload table
	CGFloat newDescriptionHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"main-content\").scrollHeight;"] floatValue];
    CGRect frame = webView.frame;
    frame.size.height = newDescriptionHeight;
    webView.frame = frame;

	if(newDescriptionHeight != descriptionHeight) {
		descriptionHeight = newDescriptionHeight;
		[self.tableView reloadData];
	}	
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	
	return YES;
}

#pragma mark EKEventEditViewDelegate
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action {
    [controller dismissModalViewControllerAnimated:YES];
}

@end
