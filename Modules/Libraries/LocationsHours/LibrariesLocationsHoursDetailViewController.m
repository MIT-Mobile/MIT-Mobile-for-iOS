#import "LibrariesLocationsHoursDetailViewController.h"
#import "LibrariesLocationsHoursTerm.h"
#import "LibrariesLocationsHoursTermHours.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITUIConstants.h"
#import "MobileRequestOperation.h"

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

@interface LibrariesLocationsHoursDetailViewController () <UITableViewDataSource, UITableViewDelegate>
- (NSString *)contentHtml;
@end

@implementation LibrariesLocationsHoursDetailViewController
- (id)init {
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
    self.contentWebView.delegate = nil;
}

#pragma mark - View lifecycle
- (void)loadView {
    UIView *myView = [self defaultApplicationView];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:myView.bounds
                                                          style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView applyStandardColors];
    self.tableView = tableView;
    
    [myView addSubview:tableView];
    self.view = myView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Detail";

    if (![self.library hasDetails]) {
        self.librariesDetailStatus = LibrariesDetailStatusLoading;
        
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"libraries"
                                                                                  command:@"locationDetail"
                                                                              parameters:@{@"library" : self.library.title}];
        request.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *jsonResult, NSString *contentType, NSError *error) {
            if (error) {
                self.librariesDetailStatus = LibrariesDetailStatusLoadingFailed;
                [self.tableView reloadData];
            } else {
                [self.library updateDetailsWithDict:jsonResult];
                [CoreDataManager saveData];
                self.librariesDetailStatus = LibrariesDetailStatusLoaded;
                [self.tableView reloadData];
            }
        };
        
        [[NSOperationQueue mainQueue] addOperation:request];
        
    } else {
        self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    }
}

- (void)viewDidUnload
{
    self.contentWebView.delegate = nil;
    self.contentWebView = nil;
    self.tableView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

#pragma mark - Table view data source
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, TITLE_WIDTH, 0)];
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
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
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
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                    UIWebView *contentWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - padding, 100)];
                    contentWebView.delegate = self;
                    // Make web view background transparent.
                    contentWebView.backgroundColor = [UIColor clearColor];
                    contentWebView.opaque = NO;
                    contentWebView.scrollView.scrollsToTop = NO;
                    
                    [contentWebView loadHTMLString:[self contentHtml] baseURL:nil];
                    [cell.contentView addSubview:contentWebView];
                    self.contentWebView = contentWebView;
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
    NSDateFormatter *startDateFormat = [[NSDateFormatter alloc] init];
    [startDateFormat setDateFormat:@"MMM d, YYYY"];
    
    NSDateFormatter *endDateFormat = [[NSDateFormatter alloc] init];
    [endDateFormat setDateFormat:@"MMM d, YYYY"];
    
    NSString *name = term.name;
    if ([name length]) {
        name = defaultTitle;
    }
    
    NSString *hoursTitle = [NSString stringWithFormat:@"%@ Hours (%@-%@)", name, [startDateFormat stringFromDate:term.startDate], [endDateFormat stringFromDate:term.endDate]];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *hourElements = [term.hours sortedArrayUsingDescriptors:@[descriptor]];
    
    NSMutableString *hoursString = [[NSMutableString alloc] init];
    for (LibrariesLocationsHoursTermHours *hoursElement in hourElements) {
        [hoursString appendFormat:@"%@ %@<br/>", hoursElement.title, hoursElement.hoursDescription];
    }
    
    return [NSString stringWithFormat:@"<span class=\"title\">%@</span><br /> %@", hoursTitle, hoursString];
    
}
- (NSString *)contentHtml {
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"libraries/libraries.html" relativeToURL:baseURL];
    NSError *error;
    NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!target) {
        DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
    }
    
    
    NSArray *termSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"termSortOrder" ascending:YES]];
    NSArray *sortedTerms = [self.library.terms sortedArrayUsingDescriptors:termSortDescriptors];
    
    NSArray *previousTerms = [sortedTerms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder < %d", 0]];
    NSArray *nextTerms = [sortedTerms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder > %d", 0]];
    LibrariesLocationsHoursTerm *term = [[sortedTerms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"termSortOrder = %d", 0]] lastObject];
    
    NSMutableString *scheduleHtml = [[NSMutableString alloc] initWithString:[self termScheduleHtml:term defaultTitle:@""]];
    for (LibrariesLocationsHoursTerm *aTerm in previousTerms) {
        [scheduleHtml appendFormat:@"<br />%@", [self termScheduleHtml:aTerm defaultTitle:@"Previous Term"]];
    }
    
    for (LibrariesLocationsHoursTerm *aTerm in nextTerms) {
        [scheduleHtml appendFormat:@"<br />%@", [self termScheduleHtml:aTerm defaultTitle:@"Next Term"]];
    }
    
    [target replaceOccurrencesOfStrings:@[@"__HOURS_HTML__", @"__SCHEDULE_HTML__"]
                            withStrings:@[self.library.hoursToday, scheduleHtml]
                                options:NSLiteralSearch];
    return target;        
}

@end
