#import "DiningRetailInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "RetailVenue.h"
#import "VenueLocation.h"
#import "RetailDay.h"
#import "CoreDataManager.h"
#import "UIImageView+WebCache.h"
#import "MITDiningRetailInfoScheduleCell.h"
#import "MITDiningCustomSeparatorCell.h"

static NSString * const kDescriptionHTMLKey = @"descriptionHTML";
static NSString * const kMenuURLKey = @"menuURL";
static NSString * const kDaysKey = @"days";
static NSString * const kCuisinesKey = @"cuisines";
static NSString * const kPaymentMethodsKey = @"paymentMethods";
static NSString * const kLocationKey = @"location";
static NSString * const kHomePageURLKey = @"homepageURL";
static NSString * const kAddToFavoritesKey = @"addToFavorites";

static CGFloat const kLeftPadding = 15.0;

static int const kWebViewTag = 4231;

@interface DiningRetailInfoViewController () <UIWebViewDelegate>

@property (nonatomic, strong) DiningHallDetailHeaderView * headerView;
@property (nonatomic, assign) CGFloat descriptionHeight;

@property (nonatomic, strong) NSArray * availableInfoKeys;

@property (nonatomic, strong) NSArray * formattedHoursData;

@end

@implementation DiningRetailInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.venue.shortName;
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self setupHeaderView];
    [self setupAvailableInfoKeys];
}

- (void)setupHeaderView
{
    self.headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    __weak DiningHallDetailHeaderView *weakHeaderView = self.headerView;
    [self.headerView.iconView setImageWithURL:[NSURL URLWithString:self.venue.iconURL]
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                        [weakHeaderView layoutIfNeeded];
                                    }];
    self.headerView.titleLabel.text = self.venue.name;
    self.headerView.infoButton.hidden = YES;
    
    if (self.venue.isOpenNow) {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#009900"];
    } else {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#d20000"];
    }
    
    NSDate *date = [NSDate date];
    RetailDay *yesterday = [self.venue dayForDate:[date dayBefore]];
    RetailDay *currentDay = [self.venue dayForDate:date];
    if ([yesterday.endTime compare:date] == NSOrderedDescending) {
        // yesterday's hours end today and are still valid
        self.headerView.timeLabel.text = [yesterday statusStringRelativeToDate:date];
    } else {
        self.headerView.timeLabel.text = [currentDay statusStringRelativeToDate:date];
    }
    self.headerView.shouldIncludeSeparator = NO;
    self.tableView.tableHeaderView = self.headerView;
}

- (void)setupAvailableInfoKeys
{
    self.availableInfoKeys = [self findAvailableInfo];
    if ([self.availableInfoKeys containsObject:kDaysKey]) {
        [self formatScheduleInfo];
    }
}

- (NSArray *)findAvailableInfo
{
    // find all viewable info that the retail venue has available
    // also add hours and location if available
    NSArray *nonInfoKeys = @[@"building", @"favorite", @"iconURL", @"name", @"shortName", @"sortableBuilding", @"url"];      // blacklist of keys we don't want to show in tableview
    NSArray * desiredRowOrder = @[kCuisinesKey, kDescriptionHTMLKey, kMenuURLKey, kPaymentMethodsKey, kDaysKey, kLocationKey, kHomePageURLKey, kAddToFavoritesKey];
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
        [usableInfoKeys addObject:kDaysKey];
    }
    
    if (self.venue.location) {
        [usableInfoKeys addObject:kLocationKey];
    }
    
    [usableInfoKeys addObject:kAddToFavoritesKey];
    
    NSArray *sortedInfo = [usableInfoKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSUInteger index1 = [desiredRowOrder indexOfObject: obj1];
        NSUInteger index2 = [desiredRowOrder indexOfObject: obj2];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)row
{
    return [self.availableInfoKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *currentRow = self.availableInfoKeys[indexPath.row];
    MITDiningCustomSeparatorCell *cell = nil;
    
    if ([currentRow isEqualToString:kDescriptionHTMLKey]) {
        cell = [self getWebViewCell];
        [self hydrateWebViewCell:cell];
    } else if ([currentRow isEqualToString:kDaysKey]) {
        cell = [self getScheduleCell];
        [(MITDiningRetailInfoScheduleCell *)cell setScheduleInfo:self.formattedHoursData];
        cell.shouldIncludeSeparator = YES;
    } else {
        cell = [self getSterilizedGeneralCell];
        
        if ([currentRow isEqualToString:kMenuURLKey]){
            cell.textLabel.text = @"menu";
            cell.detailTextLabel.text = self.venue.menuURL;
            cell.detailTextLabel.numberOfLines = 1;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kCuisinesKey]) {
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
            cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#727272"];
            
            NSString *cuisineString = [self.venue.cuisines componentsJoinedByString:@", "];
            cuisineString = [NSString stringWithFormat:@"%@\n ", cuisineString];
            cell.detailTextLabel.text = cuisineString;
            cell.shouldIncludeSeparator = NO;
        } else if ([currentRow isEqualToString:kPaymentMethodsKey]) {
            cell.textLabel.text = @"payment";
            cell.detailTextLabel.text = [self.venue.paymentMethods componentsJoinedByString:@", "];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kLocationKey]) {
            cell.textLabel.text = @"location";
            cell.detailTextLabel.text = [self.venue.location locationDisplayString];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kHomePageURLKey]) {
            cell.textLabel.text = @"home page";
            cell.detailTextLabel.text = self.venue.homepageURL;
            cell.detailTextLabel.numberOfLines = 1;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kAddToFavoritesKey]) {
            cell.textLabel.text = self.venue.favorite.boolValue ? @"Remove from Favorites" : @"Add to Favorites";
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.detailTextLabel.text = @"    ";
        }
    }
    
    return cell;
}

#pragma mark - Cell Styling

// General Cells

- (MITDiningCustomSeparatorCell *)getSterilizedGeneralCell
{
    MITDiningCustomSeparatorCell *cell = [self getGeneralCell];
    [self sterilizeCellForReuse:cell];
    cell.shouldIncludeSeparator = NO;
    return cell;
}

- (MITDiningCustomSeparatorCell *)getGeneralCell
{
    static NSString *generalCellIdentifier = @"generalCellIdentifier";
    MITDiningCustomSeparatorCell *cell = [self.tableView dequeueReusableCellWithIdentifier:generalCellIdentifier];
    if (!cell) {
        cell = [[MITDiningCustomSeparatorCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:generalCellIdentifier];
    }
    return cell;
}

- (void)sterilizeCellForReuse:(UITableViewCell *)cell
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    cell.textLabel.font = [self titleTextLabelFont];
    cell.textLabel.textColor = [UIColor mit_tintColor];
    
    cell.detailTextLabel.font = [self detailTextLabelFont];
    cell.detailTextLabel.textColor = [UIColor darkTextColor];
    cell.detailTextLabel.numberOfLines = 0;
}

// Web View Cell

- (MITDiningCustomSeparatorCell *)getWebViewCell
{
    static NSString *webViewDescriptionCellIdentifier = @"webViewDescriptionCellIdentifier";
    MITDiningCustomSeparatorCell *cell = [self.tableView dequeueReusableCellWithIdentifier:webViewDescriptionCellIdentifier];
    if (!cell) {
        cell = [[MITDiningCustomSeparatorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:webViewDescriptionCellIdentifier];
    }
    
    return cell;
}

- (void)hydrateWebViewCell:(MITDiningCustomSeparatorCell *)cell
{
    UIWebView *descriptionWebView = [self getWebViewFromCell:cell];
    NSString *htmlString = [self htmlDescriptionFromVenueHTMLString:self.venue.descriptionHTML];
    [descriptionWebView loadHTMLString:htmlString baseURL:nil];
}

- (UIWebView *)getWebViewFromCell:(UITableViewCell *)cell
{
    UIWebView *webView = (UIWebView *)[cell.contentView viewWithTag:kWebViewTag];
    if (!webView) {
        webView = [self createWebViewForCell:cell];
    }
    webView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), self.descriptionHeight);
    return webView;
}

- (UIWebView *)createWebViewForCell:(UITableViewCell *)cell
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(cell.bounds) - 40, self.descriptionHeight)];
    webView.delegate = self;
    webView.tag = kWebViewTag;
    webView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber | UIDataDetectorTypeAddress;
    webView.scrollView.scrollsToTop = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    [cell.contentView addSubview:webView];
    return webView;
}

// Schedule Cell

- (MITDiningRetailInfoScheduleCell *)getScheduleCell
{
    static NSString *scheduleCellIdentifier = @"scheduleCellIdentifier";
    MITDiningRetailInfoScheduleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:scheduleCellIdentifier];
    if (!cell) {
        cell = [[MITDiningRetailInfoScheduleCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:scheduleCellIdentifier];
    }
    return cell;
    
}

// General Font

- (UIFont *)detailTextLabelFont
{
    return [UIFont systemFontOfSize:17];
}

- (UIFont *)titleTextLabelFont
{
    return [UIFont systemFontOfSize:15.0];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *rowKey = self.availableInfoKeys[indexPath.row];
    CGFloat heightToReturn = 60.0;
    
    if ([rowKey isEqualToString:kDescriptionHTMLKey]) {
        heightToReturn = self.descriptionHeight + 20; // add some vertical padding
    } else if ([rowKey isEqualToString:kCuisinesKey]) {
        NSString *cuisineString = [self.venue.cuisines componentsJoinedByString:@", "];
        heightToReturn = [self heightForString:cuisineString];
    } else if ([rowKey isEqualToString:kLocationKey]) {
        heightToReturn = [self heightForString:[self.venue.location locationDisplayString]] + [self titleTextLabelFont].lineHeight + 10;
    } else if ([rowKey isEqualToString:kDaysKey]) {
        heightToReturn = [MITDiningRetailInfoScheduleCell heightForCellWithScheduleInfo:self.formattedHoursData];
    }
    
    return heightToReturn;
}

- (CGFloat)heightForString:(NSString *)string
{
    CGFloat maxWidth = CGRectGetWidth(self.view.bounds) - (kLeftPadding * 2.0);
    CGSize constraint = CGSizeMake(maxWidth, CGFLOAT_MAX);
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : [self detailTextLabelFont]}];
    
    CGFloat stringHeight = CGRectGetHeight([attributedString boundingRectWithSize:constraint
                                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                                          context:nil]);
    return stringHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *rowKey = self.availableInfoKeys[indexPath.row];
    if ([rowKey isEqualToString:kMenuURLKey]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.venue.menuURL]];
    } else if ([rowKey isEqualToString:kLocationKey]) {
        // link to map view
        NSString * query = ([self.venue.location.displayDescription length]) ? self.venue.location.displayDescription : self.venue.location.roomNumber;
        NSURL *url = [NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:query];
        [[UIApplication sharedApplication] openURL:url];
    } else if ([rowKey isEqualToString:kHomePageURLKey]) {
        // external url
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.venue.homepageURL]];
    } else if ([rowKey isEqualToString:kAddToFavoritesKey]) {
        [self updateFavoriteWithFavoriteCell:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

- (void)updateFavoriteWithFavoriteCell:(UITableViewCell *)cell
{
    BOOL isFavorite = ![self.venue.favorite boolValue];
    self.venue.favorite = @(isFavorite);
    cell.textLabel.text = isFavorite ? @"Remove from Favorites" : @"Add to Favorites";
    [CoreDataManager saveData];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *heightAsString = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"centered-content\").scrollHeight;"];
	CGFloat webViewHeight = [heightAsString floatValue];
    
	if(webViewHeight != self.descriptionHeight) {
		self.descriptionHeight = webViewHeight;
		[self.tableView reloadData];
    }
}

#pragma mark - HTML String Formatting

// Takes an int and an HTML String as args
- (NSString *)htmlFormatString
{
    return  @"<html>"
    "<head>"
    "<style type=\"text/css\" media=\"screen\">"
    "body { margin: 0; padding: 0; font-family: \"Helvetica Neue\", Helvetica; font-size: 13px; color: #727272;} "
    ".emptyParagraph { display: none; }"
    ".center { margin-left: auto; margin-right: auto;  width: %i;}"// Size to center in points (% doesn't work)
    "</style>"
    "</head>"
    "<body class=\"center\" id=\"centered-content\">"
    "%@" // actual description HTML string
    "</body>"
    "</html>"
    "<script type=\"text/javascript\" charset=\"utf-8\">"
    "/* hide all of the empty paragraph tags, because emergency info announcements tend to have a lot of unnecessary whitespace*/"
    "var allParagraphs = document.getElementsByTagName(\"p\");"
    "for (var i = allParagraphs.length - 1; i >= 0; i--){"
    "if (/\\S+/.test(allParagraphs[i].innerText) == false) {"
    "allParagraphs[i].className = \"emptyParagraph\";"
    "}"
    "}"
    "</script>";
}

- (NSString *)htmlDescriptionFromVenueHTMLString:(NSString *)venueHTMLString
{
    int widthOfHTMLBox = CGRectGetWidth(self.view.bounds) - (kLeftPadding * 2.0);
    return [NSString stringWithFormat:[self htmlFormatString], widthOfHTMLBox, venueHTMLString];
}

#pragma mark - Interface Orientation

- (BOOL) shouldAutorotate
{
    return NO;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end
