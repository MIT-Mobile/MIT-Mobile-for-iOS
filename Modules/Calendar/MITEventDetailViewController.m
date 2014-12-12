#import "MITEventDetailViewController.h"
#import "MITEventDetailCell.h"
#import "MITCalendarsEvent.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITWebviewCell.h"
#import "MITCalendarWebservices.h"
#import "MITConstants.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "MITMapModelController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <MessageUI/MFMailComposeViewController.h>

static NSString * const kMITEventHeaderCellNibName = @"MITEventHeaderCell";
static NSString * const kMITEventHeaderCellIdentifier = @"kMITEventHeaderIdentifier";

static NSString * const kMITEventDetailCellNibName = @"MITEventDetailCell";
static NSString * const kMITEventDetailCellIdentifier = @"kMITEventDetailIdentifier";

static NSString * const kMITEventWebviewCellNibName = @"MITWebviewCell";
static NSString * const kMITEventWebviewCellIdentifier = @"kMITEventWebviewIdentifier";

static NSInteger const kMITEventDetailsSection = 0;

static NSInteger const kMITEventDetailsEmailAlertTag = 1124;
static NSInteger const kMITEventDetailsPhoneCallAlertTag = 7643;

#pragma mark - EKEventEditViewController - PreferredContentSize
/*
 In iOS 8, when presenting this controller in a form sheet.  
 Setting preferred content size does nothing as well as attempting to set the view bounds.  
 This is the least invasive way I found to size the formsheet presentation appropriately.
 */
@interface EKEventEditViewController (ModalFormSheetSizing)
@end

@implementation EKEventEditViewController (ModalFormSheetSizing)
- (CGSize)preferredContentSize
{
    return CGSizeMake(540, 620);
}
@end

#pragma mark - MITEventDetailViewController

@interface MITEventDetailViewController () <MITWebviewCellDelegate, EKEventEditViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *rowTypes;
@property (nonatomic) BOOL isLoadingEventDetails;
@property (nonatomic) CGFloat descriptionWebviewCellHeight;

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
    
    // To prevent showing empty cells
    self.tableView.tableFooterView = [UIView new];
    
    [self setupHeader];
    
    self.title = @"Event Details";
}

#pragma mark - Public Methods

- (void)setEvent:(MITCalendarsEvent *)event
{
    if (![self.event isEqual:event]) {
        _event = event;
        
        [self refreshEventRows];
        
        if (event) {
            [self requestEventDetails];
        }
    }
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

#pragma mark - Private Methods

- (void)refreshEventRows
{
    [self setupHeader];
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    
    if (self.event.lecturer) {
        [rowTypes addObject:@(MITEventDetailRowTypeSpeaker)];
    }
	if (self.event.startAt) {
		[rowTypes addObject:@(MITEventDetailRowTypeTime)];
	}
	if (self.event.location) {
		[rowTypes addObject:@(MITEventDetailRowTypeLocation)];
	}
    if (self.event.contact.phone) {
        [rowTypes addObject:@(MITEventDetailRowTypePhone)];
    }
    if (self.event.htmlDescription) {
        [rowTypes addObject:@(MITEventDetailRowTypeDescription)];
    }
    if (self.event.contact.websiteURL) {
        [rowTypes addObject:@(MITEventDetailRowTypeWebsite)];
    }
    if (self.event.openTo) {
        [rowTypes addObject:@(MITEventDetailRowTypeOpenTo)];
    }
    if (self.event.cost) {
        [rowTypes addObject:@(MITEventDetailRowTypeCost)];
    }
    if (self.event.sponsors.anyObject) {
        [rowTypes addObject:@(MITEventDetailRowTypeSponsors)];
    }
    if (self.event.contact.email) {
        [rowTypes addObject:@(MITEventDetailRowTypeContact)];
    }
    
    self.rowTypes = rowTypes;
    [self.tableView reloadData];
    [self notifyDelegateOfSizeUpdate];
}

- (void)setupHeader
{
	CGRect tableFrame = self.tableView.frame;
    
	CGFloat titlePadding = 15;
    CGFloat titleWidth;
    titleWidth = tableFrame.size.width - titlePadding * 2;
	UIFont *titleFont = [UIFont boldSystemFontOfSize:20.0];
	CGSize titleSize = [self.event.title sizeWithFont:titleFont
									constrainedToSize:CGSizeMake(titleWidth, 2010.0)];
    titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titlePadding, titleSize.width, titleSize.height)];
	titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	titleLabel.numberOfLines = 0;
	titleLabel.font = titleFont;
	titleLabel.text = self.event.title;
    
    CGRect headerFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
	[headerView addSubview:titleLabel];
    
    if (self.event.seriesInfo) {
        UILabel *partOfSeriesLabel = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titleLabel.frame.origin.y + titleLabel.frame.size.height + 5, tableFrame.size.width - titlePadding * 2, 21)];
        partOfSeriesLabel.font = [UIFont systemFontOfSize:15];
        partOfSeriesLabel.textColor = [UIColor darkGrayColor];
        partOfSeriesLabel.text = @"This event is part of a series";
        
        headerFrame.size.height += 5 + partOfSeriesLabel.bounds.size.height;
        headerView.frame = CGRectIntegral(headerFrame);
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
    
    [MITCalendarWebservices getEventDetailsForEventURL:[NSURL URLWithString:self.event.url] withCompletion:^(MITCalendarsEvent *event, NSError *error) {
        if ([event.identifier isEqualToString:self.event.identifier]) {
            self.event = event;
            [self refreshEventRows];
        }
        self.isLoadingEventDetails = NO;
    }];
    
}

- (NSString *)htmlStringFromString:(NSString *)source
{
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
    
    void (^presentEventEditViewController)(MITCalendarsEvent *mitEvent, EKEventStore *eventStore) = ^(MITCalendarsEvent *mitEvent, EKEventStore *eventStore) {
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.calendar = [eventStore defaultCalendarForNewEvents];
        [mitEvent setUpEKEvent:event];
        
        EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];
        eventViewController.event = event;
        eventViewController.eventStore = eventStore;
        eventViewController.editViewDelegate = self;
        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            eventViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            // Setting animated to YES causes the view controller to jump towards the bottom of the iPad after presenting in landscape.
            [self presentViewController:eventViewController animated:NO completion:nil];
        } else {
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                // Necessary for scrollsToStop functionality in eventViewController in iPhone.  Otherwise the textView must be overriding it. Only available in iOS 8
                [[UITextView appearanceWhenContainedIn:[EKEventEditViewController class], nil] setScrollsToTop:NO];
            }
            [self presentViewController:eventViewController animated:YES completion:nil];
        }
        
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

- (void)notifyDelegateOfSizeUpdate
{
    if ([self.delegate respondsToSelector:@selector(eventDetailViewControllerDidUpdateSize:)]) {
        [self.delegate eventDetailViewControllerDidUpdateSize:self];
    }
}

#pragma mark - Custom Cells

- (void)configureDetailCell:(MITEventDetailCell *)detailCell ofType:(MITEventDetailRowType)type
{
    detailCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    switch (type) {
        case MITEventDetailRowTypeSpeaker: {
            [detailCell setTitle:@"speaker"];
            [detailCell setDetailText:self.event.lecturer];
            detailCell.accessoryView = nil;
            detailCell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
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
            [detailCell setDetailText:[self.event.location locationString]];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            break;
        }
        case MITEventDetailRowTypePhone: {
            [detailCell setTitle:@"phone"];
            [detailCell setDetailText:self.event.contact.phone];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            break;
        }
        case MITEventDetailRowTypeDescription: {
            // Special case, handled by webview cell
            break;
        }
        case MITEventDetailRowTypeWebsite: {
            [detailCell setTitle:@"web site"];
            [detailCell setDetailText:self.event.contact.websiteURL];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            break;
        }
        case MITEventDetailRowTypeOpenTo: {
            [detailCell setTitle:@"open to"];
            [detailCell setDetailText:self.event.openTo];
            detailCell.accessoryView = nil;
            detailCell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeCost: {
            [detailCell setTitle:@"cost"];
            NSString *costString = self.event.cost;
            [detailCell setDetailText:costString];
            detailCell.accessoryView = nil;
            detailCell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeSponsors: {
            [detailCell setTitle:@"sponsor"];
            NSString *detailText = [[self.event.sponsors.allObjects valueForKey:@"name"] componentsJoinedByString:@"\n"];
            [detailCell setDetailText:detailText];
            detailCell.accessoryView = nil;
            detailCell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeContact: {
            [detailCell setTitle:@"for more information, contact"];
            NSString *contactName = self.event.contact.name ? [NSString stringWithFormat:@"%@ ", self.event.contact.name] : @"";
            NSString *detailText = [NSString stringWithFormat:@"%@(%@)", contactName, self.event.contact.email];
            [detailCell setDetailText:detailText];
            detailCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
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
    [self notifyDelegateOfSizeUpdate];
}

#pragma mark - EKEventEditViewDelegate Methods

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kMITEventDetailsEmailAlertTag && buttonIndex == 1) {
        [UIPasteboard generalPasteboard].string = self.event.contact.email;
    } else if (alertView.tag == kMITEventDetailsPhoneCallAlertTag && buttonIndex == 1) {
        NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@", self.event.contact.phone];
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
            CGFloat h = ceil([self heightForDetailCellOfType:rowType]);
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
        case MITEventDetailRowTypeSpeaker: {
            // Nothing
            break;
        }
        case MITEventDetailRowTypeTime: {
            [self addToCalendar];
            break;
        }
        case MITEventDetailRowTypeLocation: {
            NSString *searchString = self.event.location.roomNumber ? [MITMapModelController sanitizeMapSearchString:self.event.location.roomNumber] : self.event.location.locationDescription;
            NSString *urlString = [NSString stringWithFormat:@"%@://%@/search/%@",MITInternalURLScheme,MITModuleTagCampusMap, searchString];
            NSURL *url = [NSURL URLWithString:urlString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        }
        case MITEventDetailRowTypePhone: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Call %@?", self.event.contact.phone] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            alert.tag = kMITEventDetailsPhoneCallAlertTag;
            [alert show];
            
            break;
        }
        case MITEventDetailRowTypeDescription:
            break;
        case MITEventDetailRowTypeWebsite: {
            NSString *websiteURLString = self.event.contact.websiteURL;
            NSString *urlPrefix = @"http";
            if (![websiteURLString hasPrefix:urlPrefix]) {
                websiteURLString = [NSString stringWithFormat:@"%@://%@", urlPrefix, websiteURLString];
            }
            NSURL *websiteURL = [NSURL URLWithString:websiteURLString];
            [[UIApplication sharedApplication] openURL:websiteURL];
            break;
        }
        case MITEventDetailRowTypeOpenTo:
        case MITEventDetailRowTypeCost:
        case MITEventDetailRowTypeSponsors:
            break;
        case MITEventDetailRowTypeContact: {

            if ([MFMailComposeViewController canSendMail]) {
                
                MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
                mailController.mailComposeDelegate = self;
                [mailController setSubject:self.event.title];
                [mailController setToRecipients:@[self.event.contact.email]];
                
                if (mailController) [self presentViewController:mailController animated:YES completion:nil];
                
            } else {
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Unavailable" message:@"This device doesn't appear to have native email setup properly.  Would you like to copy this email to your clipboard?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Copy Email", nil];
                alert.tag = kMITEventDetailsEmailAlertTag;
                [alert show];
                
            }
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
      
                NSString *htmlString = [NSString stringWithFormat:@"<span style=\"font-family:Helvetica; font-size: %i\">%@</span>", 17, self.event.htmlDescription];
                
                [cell setHtmlString:htmlString];
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

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
