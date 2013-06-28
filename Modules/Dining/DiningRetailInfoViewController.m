#import "DiningRetailInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "RetailVenue.h"
#import "VenueLocation.h"
#import "RetailDay.h"
#import "CoreDataManager.h"
#import "UIImageView+WebCache.h"

@interface DiningRetailInfoViewController () <UIWebViewDelegate>

@property (nonatomic, strong) DiningHallDetailHeaderView * headerView;
@property (nonatomic, strong) NSString * descriptionHtmlFormatString;
@property (nonatomic, assign) CGFloat descriptionHeight;

@property (nonatomic, strong) NSArray * sectionData;
@property (nonatomic, strong) NSArray * availableInfoKeys;

@property (nonatomic, strong) NSArray * formattedHoursData;
@property (nonatomic, strong) NSDateFormatter * daySpanFormatter;

@end

static NSString * sDescriptionHTMLKey   = @"descriptionHTML";
static NSString * sMenuURLKey           = @"menuURL";
static NSString * sDaysKey              = @"days";
static NSString * sCuisinesKey          = @"cuisines";
static NSString * sPaymentMethodsKey    = @"paymentMethods";
static NSString * sLocationKey          = @"location";
static NSString * sHomePageURLKey       = @"homepageURL";

@implementation DiningRetailInfoViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.descriptionHtmlFormatString = @"<html>"
        "<head>"
        "<style type=\"text/css\" media=\"screen\">"
        "body { margin: 0; padding: 0; font-family: \"Helvetica Neue\", Helvetica; font-size: 13px; } "
        "a { color: #990000; }"
        "</style>"
        "</head>"
        "<body id=\"content\">"
        "%@"
        "</body>"
        "</html>";
        self.descriptionHeight = 44;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView applyStandardColors];
    self.tableView.backgroundColor = [UIColor colorWithHexString:@"#e1e3e8"];
    
    self.daySpanFormatter = [[NSDateFormatter alloc] init];
    [self.daySpanFormatter setDateFormat:@"EEE"];
    
    self.title = self.venue.shortName;
    
    self.headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    __weak DiningHallDetailHeaderView *weakHeaderView = self.headerView;
    [self.headerView.iconView setImageWithURL:[NSURL URLWithString:self.venue.iconURL]
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                        [weakHeaderView layoutIfNeeded];
                                    }];
    self.headerView.titleLabel.text = self.venue.name;
    CGRect frame = self.headerView.accessoryButton.frame;
    frame.origin = CGPointMake(frame.origin.x - 10, frame.origin.y - 15);
    self.headerView.accessoryButton.frame = frame;
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"dining/bookmark"] forState:UIControlStateNormal];
    [self.headerView.accessoryButton setImage:[UIImage imageNamed:@"dining/bookmark_selected"] forState:UIControlStateSelected];
    [self.headerView.accessoryButton addTarget:self action:@selector(favoriteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.headerView.accessoryButton.selected = [self.venue.favorite boolValue];
    
    if ([self.venue isOpenNow]) {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#009900"];
    } else {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#d20000"];
    }
    
    RetailDay *currentDay = [self.venue dayForDate:[NSDate fakeDateForDining]];
    self.headerView.timeLabel.text = [currentDay statusStringRelativeToDate:[NSDate fakeDateForDining]];
    
    self.tableView.tableHeaderView = self.headerView;
    
    self.availableInfoKeys = [self findAvailableInfo];
    if ([self.availableInfoKeys containsObject:sDaysKey]) {
        [self formatScheduleInfo];
    }
}

- (NSArray *) findAvailableInfo
{
    // find all viewable info that the retail venue has available
    // also add hours and location if available
    NSArray *nonInfoKeys = @[@"building", @"favorite", @"iconURL", @"name", @"shortName", @"sortableBuilding", @"url"];      // blacklist of keys we don't want to show in tableview
    NSArray * desiredSectionOrder = @[sDescriptionHTMLKey, sMenuURLKey, sDaysKey, sCuisinesKey, sPaymentMethodsKey, sLocationKey, sHomePageURLKey];
    NSMutableArray * usableInfoKeys = [NSMutableArray array];
    NSArray *retailVenueKeys = [[[self.venue entity] attributesByName] allKeys];
    for (NSString *key in retailVenueKeys) {
        id value = [self.venue valueForKey:key];
        if (![nonInfoKeys containsObject:key] && value) {
            if ([value respondsToSelector:@selector(count)]) {
                if ([value count] > 0) {
                    [usableInfoKeys addObject:key];
                }
            } if ([value respondsToSelector:@selector(length)]) {
                if ([value length] > 0) {
                    [usableInfoKeys addObject:key];
                }
            }
        }
    }
    if (self.venue.days) {
        [usableInfoKeys addObject:sDaysKey];
    }
    if (self.venue.location.displayDescription) {
        [usableInfoKeys addObject:sLocationKey];
    }
    
    NSArray *sortedInfo = [usableInfoKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSUInteger index1 = [desiredSectionOrder indexOfObject: obj1];
        NSUInteger index2 = [desiredSectionOrder indexOfObject: obj2];
        NSComparisonResult ret = NSOrderedSame;
        if (index1 < index2)
        {
            ret = NSOrderedAscending;
        }
        else if (index1 > index2)
        {
            ret = NSOrderedDescending;
        }
        return ret;
    }];
    
    return sortedInfo;
}

- (NSArray *) desiredSectionOrder
{
    return @[sDescriptionHTMLKey, sMenuURLKey, sDaysKey, sCuisinesKey, sPaymentMethodsKey, sLocationKey, sHomePageURLKey];
}

- (void) formatScheduleInfo
{
    NSMutableArray *scheduleArray = [NSMutableArray array];
    NSArray * days = [[self.venue.days allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    RetailDay * previousDay = nil;
    for (RetailDay * day in days) {
        if (previousDay == nil) {
            // first time through, add object to list
            NSDictionary *schedule = @{@"dayStart" : day.date, @"dayEnd" : day.date, @"hours" : [day hoursSummary]};
            [scheduleArray addObject:schedule];
        } else {
            if ([[previousDay hoursSummary] isEqualToString:[day hoursSummary]]) {
                // previousDay matches current day, need to update last item in scheduleArray
                NSMutableDictionary *lastSchedule = [[scheduleArray lastObject] mutableCopy];
                lastSchedule[@"dayEnd"] = day.date;
                scheduleArray[[scheduleArray count] - 1] = lastSchedule;
            } else {
                // previous day does not match current day, add new item
                NSDictionary *schedule = @{@"dayStart" : day.date, @"dayEnd" : day.date, @"hours" : [day hoursSummary]};
                [scheduleArray addObject:schedule];
            }
        }
        previousDay = day;
    }
    self.formattedHoursData = scheduleArray;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)favoriteButtonPressed:(UIButton *)button
{
    BOOL isFavorite = ![self.venue.favorite boolValue];
    self.venue.favorite = @(isFavorite);
    button.selected = isFavorite;
    [CoreDataManager saveData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.availableInfoKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionKey = self.availableInfoKeys[section];
    if ([sectionKey isEqualToString:sDaysKey]) {
        return [self.formattedHoursData count];
    }
    return 1;
}

- (UIFont *) detailTextLabelFont
{
    return [UIFont systemFontOfSize:13];
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
    cell.textLabel.font   = [UIFont boldSystemFontOfSize:12];
    
    cell.detailTextLabel.font = [self detailTextLabelFont];
    cell.detailTextLabel.numberOfLines = 0;
    
    NSString *currentSection = self.availableInfoKeys[indexPath.section];
    
    if ([currentSection isEqualToString:sDescriptionHTMLKey]) {
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
            existingWebView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber | UIDataDetectorTypeAddress;
            [cell.contentView addSubview:existingWebView];
            existingWebView.scrollView.scrollsToTop = NO;
        }
        existingWebView.frame = CGRectMake(10, 10, CGRectGetWidth(cell.bounds) - 40, self.descriptionHeight);
        [existingWebView loadHTMLString:[NSString stringWithFormat:self.descriptionHtmlFormatString, self.venue.descriptionHTML] baseURL:nil];
        existingWebView.backgroundColor = [UIColor clearColor];
        existingWebView.opaque = NO;
        
    } else if ([currentSection isEqualToString:sMenuURLKey]){
        cell.textLabel.text = @"menu";
        cell.detailTextLabel.text = self.venue.menuURL;
        cell.detailTextLabel.numberOfLines = 1;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    } else if ([currentSection isEqualToString:sDaysKey]) {
        NSDictionary *hoursRow = self.formattedHoursData[indexPath.row];
        NSString *startDay  = [[self.daySpanFormatter stringFromDate:hoursRow[@"dayStart"]] lowercaseString];
        NSString *daySpan;
        if (![hoursRow[@"dayEnd"] isEqual: hoursRow[@"dayStart"]]) {
            NSString *endDay = [[self.daySpanFormatter stringFromDate:hoursRow[@"dayEnd"]] lowercaseString];
            daySpan = [NSString stringWithFormat:@"%@ - %@", startDay, endDay];
        } else {
            daySpan = startDay;
        }
        
        cell.textLabel.text = daySpan;
        cell.detailTextLabel.text = hoursRow[@"hours"];
    } else if ([currentSection isEqualToString:sCuisinesKey]) {
        cell.textLabel.text = @"cuisine";
        cell.detailTextLabel.text = [self.venue.cuisines componentsJoinedByString:@", "];
    } else if ([currentSection isEqualToString:sPaymentMethodsKey]) {
        cell.textLabel.text = @"payment";
        cell.detailTextLabel.text = [self.venue.paymentMethods componentsJoinedByString:@", "];
    } else if ([currentSection isEqualToString:sLocationKey]) {
        cell.textLabel.text = @"location";
        cell.detailTextLabel.text = self.venue.location.displayDescription;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
    } else if ([currentSection isEqualToString:sHomePageURLKey]) {
        cell.textLabel.text = @"home page";
        cell.detailTextLabel.text = self.venue.homepageURL;
        cell.detailTextLabel.numberOfLines = 1;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    }
    NSLog(@"DescriptionTextLabel frame :: %@", NSStringFromCGRect(cell.detailTextLabel.frame));
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionKey = self.availableInfoKeys[indexPath.section];
    if ([sectionKey isEqualToString:sDescriptionHTMLKey]) {
        return self.descriptionHeight + 20; // add some vertical padding
    } else if ([sectionKey isEqualToString:sCuisinesKey]) {
        CGSize constraint = CGSizeMake(205, CGFLOAT_MAX);
        NSString *cuisineString = [self.venue.cuisines componentsJoinedByString:@", "];
        CGSize stringSize = [cuisineString sizeWithFont:[self detailTextLabelFont] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
        return MAX(44, stringSize.height + 20);
    }
    
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionKey = self.availableInfoKeys[indexPath.section];
    if ([sectionKey isEqualToString:sMenuURLKey]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.venue.menuURL]];
    } else if ([sectionKey isEqualToString:sLocationKey]) {
        // link to map view
        NSURL *url = [NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:self.venue.location.displayDescription];
        [[UIApplication sharedApplication] openURL:url];
    } else if ([sectionKey isEqualToString:sHomePageURLKey]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.venue.homepageURL]];
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
