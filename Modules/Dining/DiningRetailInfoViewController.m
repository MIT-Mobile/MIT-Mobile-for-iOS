//
//  DiningRetailInfoViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/25/13.
//
//

#import "DiningRetailInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface DiningRetailInfoViewController () <UIWebViewDelegate>

@property (nonatomic, strong) DiningHallDetailHeaderView * headerView;
@property (nonatomic, strong) NSString * descriptionHtmlFormatString;
@property (nonatomic, assign) CGFloat descriptionHeight;

@property (nonatomic, strong) NSArray * sectionData;

@end

@implementation DiningRetailInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void) setVenueData:(NSDictionary *)venueData
{
    _venueData = venueData;
    [self parseVenueDataIntoSections];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.venueData) {
        return;
    }
    if (!self.sectionData) {
        [self parseVenueDataIntoSections];
    }
    
    self.title = self.venueData[@"name"];
    
    self.headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    self.headerView.titleLabel.text = self.venueData[@"name"];
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"global/bookmark_off"] forState:UIControlStateNormal];
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"global/bookmark_on"] forState:UIControlStateSelected];
    [self.headerView.accessoryButton addTarget:self action:@selector(bookmarkPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *scheduleDict = [self dayScheduleFromHours:self.venueData[@"hours"]];
    if ([scheduleDict[@"isOpen"] boolValue]) {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    
    NSString * scheduleString = scheduleDict[@"text"];
    self.headerView.timeLabel.text = scheduleString;
    
    self.descriptionHtmlFormatString = @"<html>"
                                        "<head>"
                                        "<style type=\"text/css\" media=\"screen\">"
                                        "body { margin: 0; padding: 0; font-family: Helvetica; font-size: 13px; } "
                                        "</style>"
                                        "</head>"
                                        "<body id=\"content\">"
                                        "%@"
                                        "</body>"
                                        "</html>";
    self.descriptionHeight = 44;
    
    self.tableView.tableHeaderView = self.headerView;

}

static const NSString * sectionIdKey = @"section_id";
static const NSString * sectionDataKey = @"section_data";

- (void) parseVenueDataIntoSections
{
    NSArray *whiteKeys = @[@"description_html", @"menu_html", @"menu_url", @"hours", @"cuisine", @"payment", @"location", @"homepage_url"];     // whitelist of dictionary keys that will correspond to order in table
    NSMutableArray * sections = [NSMutableArray array];
    
    for (NSString *key in whiteKeys) {
        if (self.venueData[key]) {
            NSDictionary * sectionData = @{sectionIdKey : key, sectionDataKey : self.venueData[key]};
            
            [sections addObject:sectionData];
        }
    }
    self.sectionData = sections;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) bookmarkPressed:(UIButton *)button
{
    
    button.selected = !button.selected;
    
}

- (NSDictionary *) dayScheduleFromHours:(NSArray *) hours
{
    NSDate *rightNow = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEEE"];
    NSString *dateString = [dateFormat stringFromDate:rightNow];
    
    NSString * dateKey = [dateString lowercaseString];
    
    NSDictionary *todaysHours;
    for (NSDictionary *day in hours) {
        if ([day[@"day"] isEqualToString:dateKey]) {
            todaysHours = day;
        }
    }
    
    if (!todaysHours) {
        // closed with no hours today
        return @{@"isOpen": @NO,
                 @"text" : @"Closed for the day"};
    }
    
    if (todaysHours[@"message"]) {
        return @{@"isOpen": @YES,
          @"text" : todaysHours[@"message"]};
    }
    
    if (todaysHours[@"start_time"] && todaysHours[@"end_time"]) {
        // need to calculate if the current time is before opening, before closing, or after closing
        [dateFormat setDateFormat:@"HH:mm"];
        NSString * openString   = todaysHours[@"start_time"];
        NSString * closeString    = todaysHours[@"end_time"];
        
        NSDate *openDate = [self dateForTodayFromTimeString:openString];
        NSDate *closeDate = [self dateForTodayFromTimeString:closeString];
        
        NSLog(@"%@", openDate);
        NSLog(@"%@", closeDate);
        NSLog(@"%@", rightNow);
        
        BOOL willOpen       = ([openDate compare:rightNow] == NSOrderedDescending); // openDate > rightNow , before the open hours for the day
        BOOL currentlyOpen  = ([openDate compare:rightNow] == NSOrderedAscending && [rightNow compare:closeDate] == NSOrderedAscending);  // openDate < rightNow < closeDate , within the open hours
        BOOL hasClosed      = ([rightNow compare:closeDate] == NSOrderedDescending); // rightNow > closeDate , after the closing time for the day
        
        [dateFormat setDateFormat:@"h:mm a"];  // adjust format for pretty printing
        
        if (willOpen) {
            NSString *closedStringFormatted = [dateFormat stringFromDate:openDate];
            return @{@"isOpen": @NO,
                     @"text" : [NSString stringWithFormat:@"Opens at %@", closedStringFormatted]};

        } else if (currentlyOpen) {
            NSString *openStringFormatted = [dateFormat stringFromDate:closeDate];
            return @{@"isOpen": @YES,
                     @"text" : [NSString stringWithFormat:@"Open until %@", openStringFormatted]};
        } else if (hasClosed) {
            return @{@"isOpen": @NO,
                     @"text" : @"Closed for the day"};
        }   
    }
    
    // the just in case
    return @{@"isOpen": @NO,
             @"text" : @"Closed for the day"};
}

- (NSDate *) dateForTodayFromTimeString:(NSString *)time
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSTimeZoneCalendarUnit fromDate:[NSDate date]];
    
    NSArray *timeComponents = [time componentsSeparatedByString:@":"];
    comp.hour = [[timeComponents objectAtIndex:0] integerValue];
    comp.minute = [[timeComponents objectAtIndex:1] integerValue];
    
    return [cal dateFromComponents:comp];
}

- (NSDate *) convertDateFromGMT:(NSDate *)gmtDate
{
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:gmtDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:gmtDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    return [[NSDate alloc] initWithTimeInterval:interval sinceDate:gmtDate];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sectionData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionDict = self.sectionData[section];
    if ([sectionDict[sectionIdKey] isEqualToString:@"hours"]) {
        return [sectionDict[sectionDataKey] count];
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    // reuse prevention
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    // configure cells style for everything but description cell (which is handled in css)
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.textLabel.font   = [UIFont fontWithName:@"Helvetica-Bold" size:11];
    
    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    cell.detailTextLabel.numberOfLines = 0;
    
    NSDictionary *sectionData = self.sectionData[indexPath.section];
    if ([sectionData[sectionIdKey] isEqualToString:@"description_html"]) {
        // cell contents are rendered in a webview
        static NSString *DescriptionCellIdentifier = @"DescriptionCell";
        cell = [tableView dequeueReusableCellWithIdentifier:DescriptionCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:DescriptionCellIdentifier];
        }
        
        UIWebView *existingWebView = (UIWebView *)[cell.contentView viewWithTag:42];
        if (!existingWebView) {
            existingWebView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(cell.bounds) - 40, self.descriptionHeight)];
            existingWebView.delegate = self;
            existingWebView.tag = 42;
            existingWebView.dataDetectorTypes = UIDataDetectorTypeAll;
            [cell.contentView addSubview:existingWebView];
        }
        existingWebView.frame = CGRectMake(10, 10, CGRectGetWidth(cell.bounds) - 40, self.descriptionHeight);
        [existingWebView loadHTMLString:[NSString stringWithFormat:self.descriptionHtmlFormatString, sectionData[sectionDataKey]] baseURL:nil];
        existingWebView.backgroundColor = [UIColor clearColor];
        existingWebView.opaque = NO;
    } else if ([sectionData[sectionIdKey] isEqualToString:@"menu_html"]) {
        cell.textLabel.text = @"menu";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    } else if ([sectionData[sectionIdKey] isEqualToString:@"menu_url"]) {
        cell.textLabel.text = @"menu";
        cell.detailTextLabel.text = sectionData[sectionDataKey];
        cell.detailTextLabel.numberOfLines = 1;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    } else if ([sectionData[sectionIdKey] isEqualToString:@"hours"]) {
        NSLog(@"%@", sectionData);
        NSDictionary *hoursRow = sectionData[sectionDataKey][indexPath.row];
        cell.textLabel.text = hoursRow[@"day"];
        if (hoursRow[@"message"]) {
            cell.detailTextLabel.text = hoursRow[@"message"];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", hoursRow[@"start_time"], hoursRow[@"end_time"]];
        }
        
    } else if ([sectionData[sectionIdKey] isEqualToString:@"location"]) {
         NSLog(@"%@", sectionData);
        cell.textLabel.text = sectionData[sectionIdKey];
    }else if ([sectionData[sectionIdKey] isEqualToString:@"homepage_url"]) {
        cell.textLabel.text = @"homepage";
        cell.detailTextLabel.numberOfLines = 1;
        cell.detailTextLabel.text = sectionData[sectionDataKey];
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                                     
    } else if ([sectionData[sectionIdKey] isEqualToString:@"cuisine"] || [sectionData[sectionIdKey] isEqualToString:@"payment"]) {
        cell.textLabel.text = sectionData[sectionIdKey];
        if ([sectionData[sectionDataKey] isKindOfClass:[NSArray class]]) {
            cell.detailTextLabel.text = [sectionData[sectionDataKey] componentsJoinedByString:@", "];
        } else {
            cell.detailTextLabel.text = sectionData[sectionDataKey];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *section = self.sectionData[indexPath.section];
    if ([section[sectionIdKey] isEqualToString:@"description_html"]) {
        return self.descriptionHeight + 10; // add some bottom padding
    }
    
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *sectionData = self.sectionData[indexPath.section];
    if ([sectionData[sectionIdKey] isEqualToString:@"menu_html"]) {
        // show menu view controller
        
    } else if ([sectionData[sectionIdKey] isEqualToString:@"menu_url"]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:sectionData[sectionDataKey]]];
    } else if ([sectionData[sectionIdKey] isEqualToString:@"location"]) {
        // link to map view
        
    } else if ([sectionData[sectionIdKey] isEqualToString:@"homepage_url"]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:sectionData[sectionDataKey]]];
    }
}

#pragma mark - WebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// calculate webView height, if it change we need to reload table
	CGFloat newDescriptionHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"content\").scrollHeight;"] floatValue];
    CGRect frame = webView.frame;
    frame.size.height = newDescriptionHeight;
    webView.frame = frame;
    
	if(newDescriptionHeight != self.descriptionHeight) {
		self.descriptionHeight = newDescriptionHeight;
		[self.tableView reloadData];
    }
}


@end
