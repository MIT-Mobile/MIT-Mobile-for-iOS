#import "CalendarDetailViewController.h"
#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "URLShortener.h"
#import "CalendarDataManager.h"
#import <EventKit/EventKit.h>
#import "MobileRequestOperation.h"

#define WEB_VIEW_PADDING 10.0
#define BUTTON_PADDING 10.0
#define kCategoriesWebViewTag 521
#define kDescriptionWebViewTag 516

@interface CalendarDetailViewController ()
@property (nonatomic,strong) UISegmentedControl *eventPager;
@property (nonatomic,getter=isLoading) BOOL loading;
@property (nonatomic,strong) NSArray *rowTypes;
@property (nonatomic,strong) UIButton *shareButton;
@property (nonatomic,strong) NSString *descriptionString;
@property (nonatomic,strong) NSString *categoriesString;
@property (nonatomic) CGFloat descriptionHeight;
@property (nonatomic) CGFloat categoriesHeight;
@end

@implementation CalendarDetailViewController
- (void)loadView
{
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController && (self.navigationController.navigationBarHidden == NO))
    {
        CGFloat navBarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
        mainFrame.origin.y += navBarHeight;
        mainFrame.size.height -= navBarHeight;
    }
    
    if (self.navigationController && (self.navigationController.toolbarHidden == NO))
    {
        CGFloat toolbarHeight = CGRectGetHeight(self.navigationController.toolbar.frame);
        mainFrame.size.height -= toolbarHeight;
    }
    
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    CGRect mainBounds = mainView.bounds;
    
    {
        CGRect tableViewFrame = CGRectMake(CGRectGetMinX(mainBounds),
                                           CGRectGetMinY(mainBounds),
                                           CGRectGetWidth(mainBounds),
                                           CGRectGetHeight(mainBounds));
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame
                                                              style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleWidth);
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.shareDelegate = self;
	
	// setup nav bar
	if (self.events.count > 1) {
		_eventPager = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                [UIImage imageNamed:MITImageNameUpArrow],
                                                                [UIImage imageNamed:MITImageNameDownArrow], nil]];
		[_eventPager setMomentary:YES];
		[_eventPager addTarget:self action:@selector(showNextEvent:) forControlEvents:UIControlEventValueChanged];
		_eventPager.segmentedControlStyle = UISegmentedControlStyleBar;
		_eventPager.frame = CGRectMake(0, 0, 80.0, _eventPager.frame.size.height);
		
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:_eventPager];
		self.navigationItem.rightBarButtonItem = segmentBarItem;
	}
    
	self.descriptionString = nil;
    self.categoriesString = nil;
	
	// set up table rows
	[self reloadEvent];
    if ([self.event hasMoreDetails] && [self.event.summary length] == 0) {
        [self requestEventDetails];
    }
	
	self.descriptionHeight = 0;
}

- (void)showNextEvent:(id)sender
{
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        NSInteger i = _eventPager.selectedSegmentIndex;
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
    if (self.isLoading) {
        return;
    }

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[self.event.eventID description], @"id", nil];
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:CalendarTag
                                                                              command:@"detail"
                                                                           parameters:params];

    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        self.loading = NO;
        
        if (error) {

        } else {
            if ([jsonResult isKindOfClass:[NSDictionary class]]
                && [[jsonResult objectForKey:@"id"] integerValue] == [self.event.eventID integerValue])
            {
                [self.event updateWithDict:jsonResult];
                [self reloadEvent];
            }
        }
    };

    self.loading = YES;
    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)reloadEvent
{
    if (self.event.url) {
        [self setupShareButton];
	}
	
	[self setupHeader];
    
    if ([self.events count] > 1) {
        NSInteger currentEventIndex = [self.events indexOfObject:self.event];
        [_eventPager setEnabled:(currentEventIndex > 0) forSegmentAtIndex:0];
        [_eventPager setEnabled:(currentEventIndex < [self.events count] - 1) forSegmentAtIndex:1];
    }
	
    NSMutableArray *rowTypes = [NSMutableArray array];
    
	if (self.event.start) {
		[rowTypes addObject:@(CalendarDetailRowTypeTime)];
	}
    
	if (self.event.shortloc || self.event.location) {
		[rowTypes addObject:@(CalendarDetailRowTypeLocation)];
	}

	if (self.event.phone) {
		[rowTypes addObject:@(CalendarDetailRowTypePhone)];
	}
    
	if (self.event.url) {
		[rowTypes addObject:@(CalendarDetailRowTypeURL)];
	}
    
	if (self.event.summary.length) {
		[rowTypes addObject:@(CalendarDetailRowTypeDescription)];
        self.descriptionString = [self htmlStringFromString:self.event.summary];
	}
    
	if ([self.event.categories count] > 0) {
		[rowTypes addObject:@(CalendarDetailRowTypeCategories)];
        
        NSMutableString *categoriesBody = [NSMutableString stringWithString:@"Categorized as:<ul>"];
        for (EventCategory *category in self.event.categories) {
            NSString *catIDString = [NSString stringWithFormat:@"catID=%d", [category.catID intValue]];
            if(category.listID) {
                catIDString = [catIDString stringByAppendingFormat:@"&listID=%@", category.listID];
            }
            NSURL *categoryURL = [NSURL internalURLWithModuleTag:CalendarTag
                                                            path:CalendarStateCategoryEventList
                                                           query:catIDString];
            [categoriesBody appendString:[NSString stringWithFormat:
                                          @"<li><a href=\"%@\">%@</a></li>", [categoryURL absoluteString], category.title]];
        }
        
        [categoriesBody appendString:@"</ul>"];
        self.categoriesString = [self htmlStringFromString:categoriesBody];
        
        UIFont *cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
        CGSize textSize = [CalendarTag sizeWithFont:cellFont];
        // one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
        self.categoriesHeight = (textSize.height + 5.0) * ([self.event.categories count] + 2);
	}
    
	self.rowTypes = rowTypes;
	[self.tableView reloadData];
}

- (void)setupShareButton {
    if (!self.shareButton) {
        CGRect tableFrame = self.tableView.frame;
        self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageNamed:@"global/share.png"];
        self.shareButton.frame = CGRectMake(tableFrame.size.width - buttonImage.size.width - BUTTON_PADDING,
                                       BUTTON_PADDING,
                                       buttonImage.size.width,
                                       buttonImage.size.height);
        [self.shareButton setImage:buttonImage forState:UIControlStateNormal];
        [self.shareButton setImage:[UIImage imageNamed:@"global/share_pressed.png"]
                          forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [self.shareButton addTarget:self
                             action:@selector(share:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupHeader {	
	CGRect tableFrame = self.tableView.frame;
	
	CGFloat titlePadding = 10.0;
    CGFloat titleWidth;
    if ([self.event hasMoreDetails]) {
        titleWidth = tableFrame.size.width - self.shareButton.frame.size.width - BUTTON_PADDING * 2 - titlePadding;
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
	if (titleSize.height < self.shareButton.frame.size.height) {
		titleSize.height += BUTTON_PADDING;
	}
	
	CGRect titleFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
	self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:titleFrame];
	[self.tableView.tableHeaderView addSubview:titleView];
    if ([self.event hasMoreDetails]) {
        [self.tableView.tableHeaderView addSubview:self.shareButton];
    }
    
    // Add border "between" header and first cell.
    if ([self.event hasMoreDetails]) {
        CGRect borderRect = CGRectMake(0,
                                       self.tableView.tableHeaderView.frame.size.height - 1,
                                       self.tableView.tableHeaderView.frame.size.width,
                                       1);
        UIView *bottomBorder = [[UIView alloc] initWithFrame:borderRect];
        bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [self.tableView.tableHeaderView addSubview:bottomBorder];
    }
    
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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)setEvent:(MITCalendarEvent *)anEvent {
	if ([self.event isEqual:anEvent] == NO) {
        _event = anEvent;
        
        self.descriptionString = nil;
        self.categoriesString = nil;
    }
    
    

}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.rowTypes count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", rowType];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        if (rowType == CalendarDetailRowTypeCategories || rowType == CalendarDetailRowTypeDescription) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell = [[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
    }
    
	[cell applyStandardFonts];
	
	switch (rowType) {
		case CalendarDetailRowTypeTime:
			cell.textLabel.text = 
            [self.event dateStringWithDateStyle:NSDateFormatterFullStyle 
                                 timeStyle:NSDateFormatterShortStyle 
                                 separator:@"\n"];
            cell.accessoryView = 
            [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
			break;
		case CalendarDetailRowTypeLocation:
			cell.textLabel.text = (self.event.location != nil) ? self.event.location : self.event.shortloc;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
			if (![self.event hasCoords]) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.accessoryView.hidden = YES;
            }
			break;
		case CalendarDetailRowTypePhone:
			cell.textLabel.text = self.event.phone;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];			
			break;
		case CalendarDetailRowTypeURL:
			cell.textLabel.text = self.event.url;
			cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			break;
		case CalendarDetailRowTypeDescription:
        {
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kDescriptionWebViewTag];
			webView.delegate = self;
			CGFloat webViewHeight;
			if (self.descriptionHeight > 0) {
				webViewHeight = self.descriptionHeight;
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
                [webView loadHTMLString:self.descriptionString
                                baseURL:nil];
                webView.tag = kDescriptionWebViewTag;
                [cell.contentView addSubview:webView];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:self.descriptionString
                                baseURL:nil];
            }
					
			break;
        }
		case CalendarDetailRowTypeCategories:
        {
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kCategoriesWebViewTag];
            CGRect frame = CGRectMake(WEB_VIEW_PADDING,
                                      WEB_VIEW_PADDING,
                                      self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING,
                                      self.categoriesHeight);
            if (!webView) {
                webView = [[UIWebView alloc] initWithFrame:frame];
				
				// prevent webView from scrolling separately from the parent scrollview
				for (id subview in webView.subviews) {
					if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
						((UIScrollView *)subview).bounces = NO;
					}
				}
				
                [webView loadHTMLString:self.categoriesString
                                baseURL:nil];
                webView.tag = kCategoriesWebViewTag;
                [cell.contentView addSubview:webView];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:self.categoriesString
                                baseURL:nil];
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
		DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
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
	NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
	
	NSString *cellText = nil;
	UIFont *cellFont = nil;
	CGFloat constraintWidth;

	switch (rowType) {
		case CalendarDetailRowTypeCategories:
			return self.categoriesHeight;

		case CalendarDetailRowTypeTime:
			cellText = [self.event dateStringWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle separator:@"\n"];
			cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
			constraintWidth = tableView.frame.size.width - 21.0;
			break;
		case CalendarDetailRowTypeDescription:
			// this is the same font defined in the html template
			if(self.descriptionHeight > 0) {
				return self.descriptionHeight + CELL_VERTICAL_PADDING * 2;
			} else {
				return 400.0;
			}

			break;
		case CalendarDetailRowTypeURL:
			cellText = self.event.url;
			cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			// 33 and 21 are from MultiLineTableViewCell.m
			constraintWidth = tableView.frame.size.width - 33.0 - 21.0;
			break;
		case CalendarDetailRowTypeLocation:
			cellText = (self.event.location != nil) ? self.event.location : self.event.shortloc;
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

	NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
	
	switch (rowType) {
        case CalendarDetailRowTypeTime:
        {
            EKEventStore *eventStore = [[EKEventStore alloc] init];
            
            void (^eventBlock)(BOOL,NSError*) = ^(BOOL granted, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
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
                            
                            EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];
                            eventViewController.event = newEvent;
                            eventViewController.eventStore = eventStore;
                            eventViewController.editViewDelegate = self;
                            [self presentModalViewController:eventViewController
                                                    animated:YES];
                    } else {
                        UIAlertView *alertView = nil;
                        if (error) {
                            alertView = [UIAlertView alertViewForError:error
                                                             withTitle:self.navigationController.title
                                                     alertViewDelegate:nil];
                        } else {
                            alertView = [[UIAlertView alloc] initWithTitle:self.navigationController.title
                                                                   message:@"Unable to save event"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"Done"
                                                         otherButtonTitles:nil];
                        }
                        
                        [alertView show];
                    }
                });
            };
            
            if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
                [eventStore requestAccessToEntityType:EKEntityTypeEvent
                                           completion:eventBlock];
            } else {
                eventBlock(YES,nil);
            }
            
            break;
        }
		case CalendarDetailRowTypeLocation:
            if ([self.event hasCoords]) {
                [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag
                                                                                      path:@"search"
                                                                                     query:self.event.shortloc]];
            }
			break;
		case CalendarDetailRowTypePhone:
		{
			NSString *phoneString = [self.event.phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
			break;
		}
		case CalendarDetailRowTypeURL:
		{
			NSURL *eventURL = [NSURL URLWithString:self.event.url];
			if (self.event.url && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
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
	return [NSString stringWithFormat:@"MIT Event: %@", self.event.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n\n%@\n\n%@",
            self.event.summary,
            self.event.url];
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
			[self.event.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
            self.event.url,
            [self.event.summary stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
}

- (NSString *)twitterUrl {
    return self.event.url;
	//return [NSString stringWithFormat:@"http://%@/e/%@", MITMobileWebDomainString, [URLShortener compressedIdFromNumber:event.eventID]];
}

- (NSString *)twitterTitle {
	return self.event.title;
}

#pragma mark JSONLoadedDelegate for background refreshing of events


#pragma mark -
#pragma mark UIWebView delegation

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// calculate webView height, if it change we need to reload table
	CGFloat newDescriptionHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"main-content\").scrollHeight;"] floatValue];
    CGRect frame = webView.frame;
    frame.size.height = newDescriptionHeight;
    webView.frame = frame;

	if(newDescriptionHeight != self.descriptionHeight) {
		self.descriptionHeight = newDescriptionHeight;
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
