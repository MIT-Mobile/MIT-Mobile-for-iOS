#import "MITDiningRetailVenueDetailViewController.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningRetailDay.h"
#import "MITDiningLocation.h"
#import "MITDiningVenueInfoCell.h"
#import "MITDiningCustomSeparatorCell.h"
#import "MITDiningRetailInfoScheduleCell.h"
#import "CoreDataManager.h"
#import "MITAdditions.h"
#import "MITMapModelController.h"

static NSString * const kDescriptionHTMLKey = @"descriptionHTML";
static NSString * const kMenuURLKey = @"menuURL";
static NSString * const kHoursKey = @"days";
static NSString * const kCuisinesKey = @"cuisines";
static NSString * const kPaymentMethodsKey = @"paymentMethods";
static NSString * const kLocationKey = @"location";
static NSString * const kHomePageURLKey = @"homepageURL";
static NSString * const kAddToFavoritesKey = @"addToFavorites";

static NSString *const kMITVenueInfoCell = @"MITDiningVenueInfoCell";

static CGFloat const kLeftPadding = 15.0;

static int const kWebViewTag = 4231;

@interface MITDiningRetailVenueDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) CGFloat descriptionHeight;
@property (nonatomic, strong) NSArray *availableInfoKeys;
@property (nonatomic, strong) NSArray *formattedHoursData;

@end

@implementation MITDiningRetailVenueDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.retailVenue.shortName;
    
    [self setupTableView];
    [self setupAvailableInfoKeys];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)targetTableViewHeight
{
    CGFloat tableHeight= 0.0;
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++) {
        for (NSInteger row = 0; row < [self tableView:self.tableView numberOfRowsInSection:section]; row++) {
            tableHeight += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    tableHeight += CGRectGetHeight(self.tableView.tableHeaderView.bounds);
    
    return tableHeight;
}

#pragma mark - TableView Setup

- (void)setupTableView
{
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UINib *cellNib = [UINib nibWithNibName:kMITVenueInfoCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITVenueInfoCell];
}

#pragma mark - Available Info Keys Setup

- (void)setupAvailableInfoKeys
{
    NSMutableArray *validInfoKeys = [NSMutableArray array];
    if (self.retailVenue.cuisine) {
        [validInfoKeys addObject:kCuisinesKey];
    }
    if (self.retailVenue.descriptionHTML) {
        [validInfoKeys addObject:kDescriptionHTMLKey];
    }
    if (self.retailVenue.menuURL) {
        [validInfoKeys addObject:kMenuURLKey];
    }
    if (self.retailVenue.payment) {
        [validInfoKeys addObject:kPaymentMethodsKey];
    }
    if (self.retailVenue.hours) {
        [validInfoKeys addObject:kHoursKey];
    }
    if (self.retailVenue.location) {
        [validInfoKeys addObject:kLocationKey];
    }
    if (self.retailVenue.homepageURL) {
        [validInfoKeys addObject:kHomePageURLKey];
    }
    
    [validInfoKeys addObject:kAddToFavoritesKey];
    self.availableInfoKeys = validInfoKeys;
    
    if ([self.availableInfoKeys containsObject:kHoursKey]) {
        [self formatScheduleInfo];
    }
}

#pragma mark - Schedule Formatting

- (void)formatScheduleInfo
{
    NSArray *orderedDays = [self.retailVenue.hours sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    NSMutableArray *scheduleArray = [NSMutableArray array];
    
    MITDiningRetailDay *previousDay = nil;
    for (MITDiningRetailDay *retailDay in orderedDays) {
        if (previousDay == nil) {
            NSDictionary *schedule = [self scheduleDictionaryFromRetailDay:retailDay];
            [scheduleArray addObject:schedule];
        } else {
            if ([[previousDay hoursSummary] isEqualToString:[retailDay hoursSummary]]) {
                NSMutableDictionary *lastSchedule = [[scheduleArray lastObject] mutableCopy];
                lastSchedule[@"dayEnd"] = retailDay.date;
                [scheduleArray removeLastObject];
                [scheduleArray addObject:lastSchedule];
            } else {
                [scheduleArray addObject:[self scheduleDictionaryFromRetailDay:retailDay]];
            }
        }
        
        previousDay = retailDay;
    }
    
    self.formattedHoursData = scheduleArray;
}

- (NSDictionary *)scheduleDictionaryFromRetailDay:(MITDiningRetailDay *)retailDay
{
    return @{@"dayStart" : retailDay.date, @"dayEnd" : retailDay.date, @"hours" : [retailDay hoursSummary]};
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    else {
        return [self.availableInfoKeys count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        MITDiningVenueInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITVenueInfoCell];
        [cell setRetailVenue:self.retailVenue];
        return cell;
    }
    
    NSString *currentRow = self.availableInfoKeys[indexPath.row];
    MITDiningCustomSeparatorCell *cell = nil;
    
    if ([currentRow isEqualToString:kDescriptionHTMLKey]) {
        cell = [self getHydratedWebViewCell];
    } else if ([currentRow isEqualToString:kHoursKey]) {
        cell = [self getScheduleCell];
        [(MITDiningRetailInfoScheduleCell *)cell setScheduleInfo:self.formattedHoursData];
        cell.shouldIncludeSeparator = YES;
    } else {
        cell = [self getSterilizedGeneralCell];
        
        if ([currentRow isEqualToString:kMenuURLKey]){
            cell.textLabel.text = @"menu";
            cell.detailTextLabel.text = self.retailVenue.menuURL;
            cell.detailTextLabel.numberOfLines = 0;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kCuisinesKey]) {
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
            cell.detailTextLabel.textColor = [UIColor colorWithHexString:@"#727272"];
            
            NSString *cuisineString = [self.retailVenue.cuisine componentsJoinedByString:@", "];
            cuisineString = [NSString stringWithFormat:@"%@\n ", cuisineString];
            cell.detailTextLabel.text = cuisineString;
        } else if ([currentRow isEqualToString:kPaymentMethodsKey]) {
            cell.textLabel.text = @"payment";
            cell.detailTextLabel.text = [self.retailVenue.payment componentsJoinedByString:@", "];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kLocationKey]) {
            cell.textLabel.text = @"location";
            cell.detailTextLabel.text = [self.retailVenue.location locationDisplayString];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kHomePageURLKey]) {
            cell.textLabel.text = @"home page";
            cell.detailTextLabel.text = self.retailVenue.homepageURL;
            cell.detailTextLabel.numberOfLines = 0;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            cell.shouldIncludeSeparator = YES;
        } else if ([currentRow isEqualToString:kAddToFavoritesKey]) {
            cell.textLabel.text = self.retailVenue.favorite.boolValue ? @"Remove from Favorites" : @"Add to Favorites";
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

- (MITDiningCustomSeparatorCell *)getHydratedWebViewCell
{
    MITDiningCustomSeparatorCell *cell = [self getWebViewCell];
    [self hydrateWebViewCell:cell];
    return cell;
}

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
    NSString *htmlString = [self htmlDescriptionFromVenueHTMLString:self.retailVenue.descriptionHTML];
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
    return [UIFont systemFontOfSize:12.0];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
      return [MITDiningVenueInfoCell heightForRetailVenue:self.retailVenue tableViewWidth:self.tableView.frame.size.width];
    }
    
    NSString *rowKey = self.availableInfoKeys[indexPath.row];
    CGFloat heightToReturn = 60.0;
    
    if ([rowKey isEqualToString:kDescriptionHTMLKey]) {
        heightToReturn = self.descriptionHeight;
    } else if ([rowKey isEqualToString:kCuisinesKey]) {
        NSString *cuisineString = [self.retailVenue.cuisine componentsJoinedByString:@", "];
        heightToReturn = [self heightForString:cuisineString];
    } else if ([rowKey isEqualToString:kLocationKey]) {
        heightToReturn = [self heightForString:[self.retailVenue.location locationDisplayString]] + [self titleTextLabelFont].lineHeight + 10;
    } else if ([rowKey isEqualToString:kHomePageURLKey]) {
        heightToReturn = [self heightForString:self.retailVenue.homepageURL] + [self titleTextLabelFont].lineHeight + 10;
    } else if ([rowKey isEqualToString:kMenuURLKey]) {
        heightToReturn = [self heightForString:self.retailVenue.menuURL] + [self titleTextLabelFont].lineHeight + 10;
    } else if ([rowKey isEqualToString:kHoursKey]) {
        heightToReturn = [MITDiningRetailInfoScheduleCell heightForCellWithScheduleInfo:self.formattedHoursData];
    }
    
    return heightToReturn;
}

- (CGFloat)heightForString:(NSString *)string
{
    CGFloat maxWidth = CGRectGetWidth(self.view.bounds) - (kLeftPadding * 4.0);
    CGSize constraint = CGSizeMake(maxWidth, CGFLOAT_MAX);
    NSDictionary *attributes = @{NSFontAttributeName : [self detailTextLabelFont]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string
                                                                           attributes:attributes];
    CGRect boundingRect = [attributedString boundingRectWithSize:constraint
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                         context:nil];
    return CGRectGetHeight(boundingRect);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *rowKey = self.availableInfoKeys[indexPath.row];
    if ([rowKey isEqualToString:kMenuURLKey]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.retailVenue.menuURL]];
    } else if ([rowKey isEqualToString:kLocationKey]) {
        if (self.retailVenue.location.mitRoomNumber) {
            [MITMapModelController openMapWithRoomNumber:self.retailVenue.location.mitRoomNumber];
        }
        else {
            [MITMapModelController openMapWithSearchString:self.retailVenue.location.locationDescription];
        }
    } else if ([rowKey isEqualToString:kHomePageURLKey]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.retailVenue.homepageURL]];
    } else if ([rowKey isEqualToString:kAddToFavoritesKey]) {
        [self updateFavoriteWithFavoriteCell:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

- (void)updateFavoriteWithFavoriteCell:(UITableViewCell *)cell
{
    BOOL isFavorite = ![self.retailVenue.favorite boolValue];
    self.retailVenue.favorite = @(isFavorite);
    cell.textLabel.text = isFavorite ? @"Remove from Favorites" : @"Add to Favorites";
    [CoreDataManager saveData];
    
    if ([self.delegate respondsToSelector:@selector(retailDetailViewController:didUpdateFavoriteStatusForVenue:)]) {
        [self.delegate retailDetailViewController:self didUpdateFavoriteStatusForVenue:self.retailVenue];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *heightAsString = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"centered-content\").scrollHeight;"];
	CGFloat webViewHeight = [heightAsString floatValue];
    
	if (webViewHeight != self.descriptionHeight) {
		self.descriptionHeight = webViewHeight;
		[self.tableView reloadData];
        if ([self.delegate respondsToSelector:@selector(retailDetailViewControllerDidUpdateSize:)]) {
            [self.delegate retailDetailViewControllerDidUpdateSize:self];
        }
    }
}

#pragma mark - HTML String Formatting

// Takes an int(width size in points) and an HTML String as args
- (NSString *)htmlFormatString
{
    return  @"<html>"
    "<head>"
    "<style type=\"text/css\" media=\"screen\">"
    "body { margin: 0; padding: 0; font-family: \"Helvetica Neue\", Helvetica; font-size: 13px; color: #727272;} "
    ".emptyParagraph { display: none; }"
    ".center { margin-left: auto; margin-right: auto;  width: %i;}" // Size to center in points (% doesn't work)
    "</style>"
    "</head>"
    "<body class=\"center\" id=\"centered-content\">"
    "%@" // actual description HTML string
    "</body>"
    "</html>"
    "<script type=\"text/javascript\" charset=\"utf-8\">"
    // hide all of the empty paragraph tags, because emergency info announcements tend to have a lot of unnecessary whitespace
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

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end
