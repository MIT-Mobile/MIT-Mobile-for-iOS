#import "LibrariesLocationsHoursDetailViewController.h"
#import "LibrariesLocationsHoursTerm.h"
#import "LibrariesLocationsHoursTermHours.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITUIConstants.h"

typedef enum 
{
    TITLE_ROW = 0,
    LOADING_STATUS_ROW = 1,
    // PHONE_ROW replaces LOADING_STATUS_ROW after the load is done.
    PHONE_ROW = 1, 
    LOCATION_ROW,
    CONTENT_ROW
}
LocationsHoursTableRows;

#define TITLE_ROW_TAG 423
#define PADDING 11
#define TITLE_WIDTH 278

@interface LibrariesLocationsHoursDetailViewController (Private)
- (NSString *)contentHtml;
@end

@implementation LibrariesLocationsHoursDetailViewController
@synthesize library;
@synthesize librariesDetailStatus;
@synthesize request;
@synthesize contentRowHeight;
@synthesize contentWebView;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.contentRowHeight = 0;
    }
    return self;
}

- (void)dealloc
{
    self.request = nil;
    self.library = nil;
    self.contentWebView.delegate = nil;
    self.contentWebView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView applyStandardColors];
    
    self.title = @"Detail";

    if (![self.library hasDetails]) {
        self.librariesDetailStatus = LibrariesDetailStatusLoading;
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:self.library.title forKey:@"library"];
        self.request = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"locationDetail" parameters:params] autorelease];
        self.request.jsonDelegate = self;
        [self.request start];
    } else {
        self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    }
}

- (void)viewDidUnload
{
    self.contentWebView.delegate = nil;
    self.contentWebView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.librariesDetailStatus == LibrariesDetailStatusLoaded) {
        return 4; // title, phone, location, content
    } else {
        return 2; // title, loading indicator
    }
}

- (UITableViewCell *)titleRowWithTable:(UITableView *)tableView {
    NSString *cellIdentifier = @"titleRow";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, TITLE_WIDTH, 0)] autorelease];
        titleLabel.tag = TITLE_ROW_TAG;
        titleLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        titleLabel.textColor = CELL_STANDARD_FONT_COLOR;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.numberOfLines = 0;
        [cell.contentView addSubview:titleLabel];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (UITableViewCell *)defaultRowWithTable:(UITableView *)tableView {
    NSString *cellIdentifier = @"defaultRow";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
        [cell applyStandardFonts];
    }  
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row == TITLE_ROW) {
        cell = [self titleRowWithTable:tableView];
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:TITLE_ROW_TAG];
        titleLabel.text = self.library.title;
        CGSize titleSize = [self.library.title sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] 
                                          constrainedToSize:CGSizeMake(TITLE_WIDTH, 500)];
        titleLabel.frame = CGRectMake(PADDING, PADDING, TITLE_WIDTH, titleSize.height);
    } else {
        if (self.librariesDetailStatus != LibrariesDetailStatusLoaded) {
            cell = [self defaultRowWithTable:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;            
            if (self.librariesDetailStatus == LibrariesDetailStatusLoading) {
                cell.textLabel.text = @"Loading...";
            } else if (self.librariesDetailStatus == LibrariesDetailStatusLoadingFailed) {
                cell.textLabel.text = @"Failed loading details";
            }
        } else {
            if (indexPath.row == PHONE_ROW) {
                cell = [self defaultRowWithTable:tableView];
                cell.textLabel.text = self.library.telephone;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else if (indexPath.row == LOCATION_ROW) {
                cell = [self defaultRowWithTable:tableView];
                cell.textLabel.text = [NSString stringWithFormat:@"Room %@", self.library.location];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;                
            } else if (indexPath.row == CONTENT_ROW) {
                NSString *cellIdentifier = @"contentRow";
                cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                
                CGFloat padding;
                switch (self.tableView.style) {
                    case UITableViewStyleGrouped:
                        padding = 20.0;
                        break;
                        
                    case UITableViewStylePlain:
                    default:
                        padding = 0.0;
                        break;
                }
                
                if (cell == nil) {
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
                    self.contentWebView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - padding, 100)] autorelease];
                    self.contentWebView.delegate = self;      
                    // Make web view background transparent.
                    self.contentWebView.backgroundColor = [UIColor clearColor];
                    self.contentWebView.opaque = NO;
                    
                    [self.contentWebView loadHTMLString:[self contentHtml] baseURL:nil];
                    [cell.contentView addSubview:self.contentWebView];
                }
            }
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.librariesDetailStatus == LibrariesDetailStatusLoaded) {
        if (indexPath.row == PHONE_ROW) {
            NSString *phoneNumber = [self.library.telephone stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
            if ([[UIApplication sharedApplication] canOpenURL:externURL])
                [[UIApplication sharedApplication] openURL:externURL];
        } else if (indexPath.row == LOCATION_ROW) {
            [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:self.library.location]];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == CONTENT_ROW) {
        return self.contentRowHeight;
    } if (indexPath.row == TITLE_ROW) {
        CGSize titleSize = [self.library.title sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] 
                                          constrainedToSize:CGSizeMake(TITLE_WIDTH, 500)];
        return titleSize.height + 2*PADDING;
    } else {
        return tableView.rowHeight;
    }
}

#pragma mark - JSONLoaded delegate methods

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    [self.library updateDetailsWithDict:JSONObject];
    [CoreDataManager saveData];
    self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    [self.tableView reloadData];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    self.librariesDetailStatus = LibrariesDetailStatusLoadingFailed;
    [self.tableView reloadData];
}

#pragma mark - UIWebView delegate 

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGFloat webViewHeight = [webView sizeThatFits:CGSizeZero].height;
    self.contentRowHeight = webViewHeight + 10;
    CGRect contentWebViewFrame = self.contentWebView.frame;
    contentWebViewFrame.size.height = webViewHeight;
    self.contentWebView.frame = contentWebViewFrame;
    [self.tableView reloadData];
}

- (NSString *)termScheduleHtml:(LibrariesLocationsHoursTerm *)term defaultTitle:(NSString *)defaultTitle{
    NSDateFormatter *startDateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [startDateFormat setDateFormat:@"MMM d, YYYY"];
    
    NSDateFormatter *endDateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [endDateFormat setDateFormat:@"MMM d, YYYY"];
    
    NSString *name = term.name;
    if (name == nil) {
        name = defaultTitle;
    }
    NSString *hoursTitle = [NSString stringWithFormat:@"%@ Hours (%@-%@)", name, [startDateFormat stringFromDate:term.startDate], [endDateFormat stringFromDate:term.endDate]];
    
    NSString *hoursString = @"";
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *hourElements = [term.hours sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    for (LibrariesLocationsHoursTermHours *hoursElement in hourElements) {
        hoursString = 
        [hoursString stringByAppendingFormat:@"%@ %@<br/>", 
         hoursElement.title, hoursElement.hoursDescription];
    }
    
    return [NSString stringWithFormat:@"<span class=\"title\">%@</span><br /> %@", hoursTitle, hoursString];
    
}
- (NSString *)contentHtml {
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"libraries/libraries.html" relativeToURL:baseURL];
    NSError *error;
    NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!target) {
        ELog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
    }
    
    LibrariesLocationsHoursTerm *term = [[self.library.terms filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder = %d", 0]] anyObject];
    
    NSArray *previousTerms = [[self.library.terms filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder < %d", 0]] 
                              sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"termSortOrder" ascending:NO]]];
    
    NSArray *nextTerms = [[self.library.terms filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder > %d", 0]] 
                          sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"termSortOrder" ascending:YES]]];
    
    NSString *scheduleHtml = [self termScheduleHtml:term defaultTitle:@""];
    for (LibrariesLocationsHoursTerm *aTerm in previousTerms) {
        scheduleHtml = [scheduleHtml stringByAppendingFormat:@"<br />%@", [self termScheduleHtml:aTerm defaultTitle:@"Previous Term"]];
    }
    for (LibrariesLocationsHoursTerm *aTerm in nextTerms) {
        scheduleHtml = [scheduleHtml stringByAppendingFormat:@"<br />%@", [self termScheduleHtml:aTerm defaultTitle:@"Next Term"]];
    }
    
    [target 
     replaceOccurrencesOfStrings:
     [NSArray arrayWithObjects:@"__HOURS_HTML__", @"__SCHEDULE_HTML__", nil]
     withStrings:
     [NSArray arrayWithObjects:self.library.hoursToday, scheduleHtml, nil] 
     options:NSLiteralSearch];
    return target;        
}
@end
