#import "MITEventDetailViewController.h"
#import "MITEventDetailCell.h"
#import "MITCalendarEvent.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITWebviewCell.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

static NSString * const kMITEventHeaderCellNibName = @"MITEventHeaderCell";
static NSString * const kMITEventHeaderCellIdentifier = @"kMITEventHeaderIdentifier";

static NSString * const kMITEventDetailCellNibName = @"MITEventDetailCell";
static NSString * const kMITEventDetailCellIdentifier = @"kMITEventDetailIdentifier";

static NSString * const kMITEventWebviewCellNibName = @"MITWebviewCell";
static NSString * const kMITEventWebviewCellIdentifier = @"kMITEventWebviewIdentifier";

static NSInteger const kMITEventDetailsSection = 0;

static NSInteger const kMITEventDetailsPhoneCallAlertTag = 200;

@interface MITEventDetailViewController () <MITWebviewCellDelegate, EKEventEditViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *rowTypes;
@property (nonatomic) BOOL isLoadingEventDetails;
@property (nonatomic) CGFloat descriptionWebviewCellHeight;
@property (nonatomic, strong) NSString *descriptionHtmlString;

@end

@implementation MITEventDetailViewController

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
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:kMITEventHeaderCellNibName bundle:nil] forCellReuseIdentifier:kMITEventHeaderCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITEventDetailCellNibName bundle:nil] forCellReuseIdentifier:kMITEventDetailCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITEventWebviewCellNibName bundle:nil] forCellReuseIdentifier:kMITEventWebviewCellIdentifier];
    
    [self setupHeader];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods

- (void)setEvent:(MITCalendarEvent *)event
{
    if (![self.event isEqual:event]) {
        _event = event;
        
        [self refreshEventRows];
        
        if ([self.event hasMoreDetails] && [self.event.summary length] == 0) {
            [self requestEventDetails];
        }
    }
}

#pragma mark - Private Methods

- (void)refreshEventRows
{
    [self setupHeader];
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    
	if (self.event.start) {
		[rowTypes addObject:@(MITEventDetailRowTypeTime)];
	}
    
	if (self.event.shortloc || self.event.location) {
		[rowTypes addObject:@(MITEventDetailRowTypeLocation)];
	}
    
	if (self.event.phone) {
		[rowTypes addObject:@(MITEventDetailRowTypePhone)];
	}
    
	if (self.event.url) {
		[rowTypes addObject:@(MITEventDetailRowTypeWebsite)];
	}
    
	if (self.event.summary.length) {
		[rowTypes addObject:@(MITEventDetailRowTypeDescription)];
        self.descriptionHtmlString = [self htmlStringFromString:self.event.summary];
	}
    
    self.rowTypes = rowTypes;
    [self.tableView reloadData];
}

- (void)setupHeader {
	CGRect tableFrame = self.tableView.frame;
    
	CGFloat titlePadding = 15;
    CGFloat titleWidth;
    titleWidth = tableFrame.size.width - titlePadding * 2;
	UIFont *titleFont = [UIFont boldSystemFontOfSize:20.0];
	CGSize titleSize = [self.event.title sizeWithFont:titleFont
									constrainedToSize:CGSizeMake(titleWidth, 2010.0)];
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titlePadding, titleSize.width, titleSize.height)];
	titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	titleLabel.numberOfLines = 0;
	titleLabel.font = titleFont;
	titleLabel.text = self.event.title;
    
    CGRect headerFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
	[headerView addSubview:titleLabel];
    
    if (YES) {
        UILabel *partOfSeriesLabel = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titleLabel.frame.origin.y + titleLabel.frame.size.height + 5, tableFrame.size.width - titlePadding * 2, 21)];
        partOfSeriesLabel.font = [UIFont systemFontOfSize:15];
        partOfSeriesLabel.textColor = [UIColor darkGrayColor];
        partOfSeriesLabel.text = @"This event is part of a series";
        
        headerFrame.size.height += 5 + partOfSeriesLabel.bounds.size.height;
        headerView.frame = headerFrame;
        [headerView addSubview:partOfSeriesLabel];
    }
    
    self.tableView.tableHeaderView = headerView;
}

- (void)requestEventDetails
{
    if (self.isLoadingEventDetails) {
        return;
    }
    
    self.isLoadingEventDetails = YES;
    
    NSURLRequest *request = [NSURLRequest requestForModule:CalendarTag command:@"detail" parameters:@{@"id":[self.event.eventID stringValue]}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *jsonResult) {
        self.isLoadingEventDetails = NO;
        
        if ([jsonResult isKindOfClass:[NSDictionary class]]) {
            if ([jsonResult[@"id"] integerValue] == [self.event.eventID integerValue]) {
                [self.event updateWithDict:jsonResult];
                [self refreshEventRows];
            }
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        self.isLoadingEventDetails = NO;
        DDLogVerbose(@"Calendar 'detail' request failed: %@",[error localizedDescription]);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (NSString *)htmlStringFromString:(NSString *)source {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:@"calendar/events_template.html" relativeToURL:baseURL];
	NSError *error;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}
    
    CGFloat webHorizontalPadding = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 15. : 10.;
    
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", self.tableView.frame.size.width - 2 * webHorizontalPadding];
    [target replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, target.length)];
    
	[target replaceOccurrencesOfStrings:@[@"__BODY__"]
							withStrings:@[source]
								options:NSLiteralSearch];
    
	return [NSString stringWithString:target];
}

- (void)addToCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    void (^presentEventEditViewController)(MITCalendarEvent *mitEvent, EKEventStore *eventStore) = ^(MITCalendarEvent *mitEvent, EKEventStore *eventStore) {
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.calendar = [eventStore defaultCalendarForNewEvents];
        event.notes = mitEvent.summary;
        [mitEvent setUpEKEvent:event];
        
        EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];
        eventViewController.event = event;
        eventViewController.eventStore = eventStore;
        eventViewController.editViewDelegate = self;
        [self presentViewController:eventViewController animated:YES completion:NULL];
    };
    
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    presentEventEditViewController(self.event, eventStore);
                });
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not access your calendar" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            }
        }];
    } else {
        presentEventEditViewController(self.event, eventStore);
    }
}

#pragma mark - Custom Cells

- (void)configureDetailCell:(MITEventDetailCell *)detailCell ofType:(MITEventDetailRowType)type
{
    switch (type) {
        case MITEventDetailRowTypeTime: {
            [detailCell setTitle:@"time"];
            NSString *timeDetailString = [self.event dateStringWithDateStyle:NSDateFormatterFullStyle
                                                                   timeStyle:NSDateFormatterShortStyle
                                                                   separator:@"\n"];
            [detailCell setDetailText:timeDetailString];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
            break;
        }
        case MITEventDetailRowTypeLocation: {
            [detailCell setTitle:@"location"];
            NSString *locationDetailString = (self.event.location != nil) ? self.event.location : self.event.shortloc;
            [detailCell setDetailText:locationDetailString];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            break;
        }
        case MITEventDetailRowTypePhone: {
            [detailCell setTitle:@"phone"];
            [detailCell setDetailText:self.event.phone];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            break;
        }
        case MITEventDetailRowTypeWebsite: {
            [detailCell setTitle:@"web site"];
            [detailCell setDetailText:self.event.url];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            break;
        }
        case MITEventDetailRowTypeDescription: {
            // Special case, handled by webview cell
            break;
        }
    }
    
    [detailCell setNeedsUpdateConstraints];
    [detailCell updateConstraintsIfNeeded];
    detailCell.bounds = CGRectMake(0, 0, self.tableView.bounds.size.width, detailCell.bounds.size.height);
    [detailCell setNeedsLayout];
    [detailCell layoutIfNeeded];
}

- (CGFloat)heightForDetailCellOfType:(MITEventDetailRowType)type
{
    static MITEventDetailCell *detailCell;
    if (!detailCell) {
        detailCell = [[NSBundle mainBundle] loadNibNamed:kMITEventDetailCellNibName owner:self options:nil][0];
    }
    
    if (type == MITEventDetailRowTypeDescription) {
        return self.descriptionWebviewCellHeight;
    } else {
        [self configureDetailCell:detailCell ofType:type];
    }
    
    CGFloat height = [detailCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height;   // add pt for cell separator;
    
    return height;
}

#pragma mark - MITWebviewCellDelegate Methods

- (void)webviewCellDidResize:(MITWebviewCell *)webviewCell toHeight:(CGFloat)newHeight
{
    self.descriptionWebviewCellHeight = newHeight;
    [self.tableView reloadData];
}

#pragma mark - EKEventEditViewDelegate Methods

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kMITEventDetailsPhoneCallAlertTag && buttonIndex == 1) {
        NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@", self.event.phone];
        NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
        [[UIApplication sharedApplication] openURL:phoneURL];
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITEventDetailsSection: {
            MITEventDetailRowType rowType = [self.rowTypes[indexPath.row] integerValue];
            CGFloat h = [self heightForDetailCellOfType:rowType];
            NSLog(@"height: %f", h);
            return h;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
    
    switch (rowType) {
        case MITEventDetailRowTypeTime: {
            [self addToCalendar];
            break;
        }
        case MITEventDetailRowTypeLocation: {
            // Will need to somehow pop to MITMapPlace? Discussion about how to do this was not conclusive
            // Depends on how we are setting up the hamburger menu navigation and such
            break;
        }
        case MITEventDetailRowTypePhone: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Call %@?", self.event.phone] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            alert.tag = kMITEventDetailsPhoneCallAlertTag;
            [alert show];
            
            break;
        }
        case MITEventDetailRowTypeWebsite: {
            NSURL *websiteURL = [NSURL URLWithString:self.event.url];
            [[UIApplication sharedApplication] openURL:websiteURL];
            break;
        }
        case MITEventDetailRowTypeDescription: {
            // Do nothing
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITEventDetailsSection: {
            return self.rowTypes.count;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITEventDetailsSection: {
            NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
            
            if (rowType == MITEventDetailRowTypeDescription) {
                // return webview cell height
                MITWebviewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITEventWebviewCellIdentifier];
                [cell setHTMLString:self.descriptionHtmlString];
                cell.delegate = self;
                return cell;
            } else {
                MITEventDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITEventDetailCellIdentifier];
                [self configureDetailCell:cell ofType:rowType];
                return cell;
            }
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

@end
