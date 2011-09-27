#import "SettingsTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MITMobileServerConfiguration.h"
#import "MITDeviceRegistration.h"
#import "MITLogging.h"

NSString * const SectionTitleString = @"Notifications";
NSString * const SectionSubtitleString = @"Turn off Notifications to disable alerts for that module.";
#define TITLE_HEIGHT 20.0
#define SUBTITLE_HEIGHT NAVIGATION_BAR_HEIGHT
#define PADDING 10.0

#define NOTIFICATION_SECTION_INDEX 0
#define SERVER_SECTION_INDEX 1

@interface SettingsTableViewController ()
@property (nonatomic,retain) UIGestureRecognizer* showServerListGesture;
@property (nonatomic,retain) UIGestureRecognizer* hideServerListGesture;

- (void)gestureWasRecognized:(UIGestureRecognizer*)gesture;
- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled;
- (void)serverSelectionDidChangeFrom:(NSInteger)old to:(NSInteger)new;

- (void)addRequest:(MITMobileWebAPI*)request withTag:(NSString*)tag;
- (MITMobileWebAPI*)requestWithTag:(NSString*)tag;
- (void)removeRequestWithTag:(NSString*)tag;
- (NSUInteger)numberOfActiveRequests;
@end

@implementation SettingsTableViewController

@synthesize notifications = _notifications;
@synthesize apiRequests = _apiRequests;
@synthesize showServerListGesture = _showAdvancedGesture;
@synthesize hideServerListGesture = _hideAdvancedGesture;


- (void)dealloc {
    self.notifications = nil;
    self.showServerListGesture = nil;
    self.hideServerListGesture = nil;
    
    if (_requestQueue) {
        dispatch_release(_requestQueue);
    }
	self.apiRequests = nil;
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    
    _requestQueue = dispatch_queue_create("SettingsAPIQueue", NULL);
    self.apiRequests = [NSMutableDictionary dictionary];
    
    [self.tableView applyStandardColors];

    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.notifications = [appDelegate.modules filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pushNotificationSupported == TRUE"]];
    
    UISwipeGestureRecognizer *gesture = nil;
    
    gesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(gestureWasRecognized:)] autorelease];
    gesture.direction = UISwipeGestureRecognizerDirectionLeft;
    gesture.numberOfTouchesRequired = 2;
    self.showServerListGesture = gesture;
    [self.view addGestureRecognizer:gesture];

    gesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(gestureWasRecognized:)] autorelease];
    gesture.direction = UISwipeGestureRecognizerDirectionRight;
    gesture.numberOfTouchesRequired = 2;
    self.hideServerListGesture = gesture;
    
    _selectedRow = NSUIntegerMax;
    _advancedOptionsVisible = NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    [super viewDidUnload];
    self.notifications = nil;
    self.showServerListGesture = nil;
    self.hideServerListGesture = nil;
    _advancedOptionsVisible = NO;
}

#pragma mark Advanced view methods
- (void)gestureWasRecognized:(UIGestureRecognizer*)gesture
{
    if (gesture == self.showServerListGesture) {
        [self.view removeGestureRecognizer:self.showServerListGesture];
        [self.view addGestureRecognizer:self.hideServerListGesture];
        _advancedOptionsVisible = YES;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:SERVER_SECTION_INDEX]
                      withRowAnimation:UITableViewRowAnimationFade];
    } else if (gesture == self.hideServerListGesture) {
        _advancedOptionsVisible = NO;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:SERVER_SECTION_INDEX]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.view removeGestureRecognizer:self.hideServerListGesture];
        [self.view addGestureRecognizer:self.showServerListGesture];
    }
}


#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_advancedOptionsVisible) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
        case NOTIFICATION_SECTION_INDEX:
            rows = [self.notifications count];
            break;
        case SERVER_SECTION_INDEX:
            rows = (_advancedOptionsVisible) ? [MITMobileWebGetAPIServerList() count] : 0;
            break;
        default:
            rows = 0;
            break;
    }
    return rows;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *result = nil;
    UILabel *titleView = nil;
    UILabel *subtitleView = nil;
    
    if (section == NOTIFICATION_SECTION_INDEX) {
        result = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, SUBTITLE_HEIGHT + TITLE_HEIGHT)] autorelease];
        
        titleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, 200, TITLE_HEIGHT)];
        titleView.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
        titleView.textColor = GROUPED_SECTION_FONT_COLOR;
        titleView.backgroundColor = [UIColor clearColor];
        titleView.text = SectionTitleString;
                          
        subtitleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING,
                                                                 round(TITLE_HEIGHT + 1.5 * PADDING),
                                                                 round(tableView.frame.size.width-2 * PADDING),
                                                                 SUBTITLE_HEIGHT)];
        subtitleView.numberOfLines = 0;
        subtitleView.backgroundColor = [UIColor clearColor];
        subtitleView.lineBreakMode = UILineBreakModeWordWrap;
        subtitleView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        subtitleView.text = SectionSubtitleString;
        
        [result addSubview:titleView];
        [titleView release];
        [result addSubview:subtitleView];
        [subtitleView release];
    } else if (section == SERVER_SECTION_INDEX) {
        if (_advancedOptionsVisible) {
            result = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, TITLE_HEIGHT)] autorelease];
            titleView = [[[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, tableView.frame.size.width, TITLE_HEIGHT)] autorelease];
            titleView.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
            titleView.textColor = GROUPED_SECTION_FONT_COLOR;
            titleView.backgroundColor = [UIColor clearColor];
            titleView.text = @"API Servers";
            
            [result addSubview:titleView];
        }
    }
    
	return result;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case NOTIFICATION_SECTION_INDEX:
            return SUBTITLE_HEIGHT + TITLE_HEIGHT + 2.5 * PADDING;
            
        case SERVER_SECTION_INDEX:
            return TITLE_HEIGHT + 2.5 * PADDING;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString* AdvancedCellIdentifier = @"AdvancedCell";
    
    UITableViewCell *cell = nil;
    
    if (indexPath.section == NOTIFICATION_SECTION_INDEX) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
            
            UISwitch *aSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            [aSwitch addTarget:self action:@selector(switchDidToggle:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = aSwitch;
        }
        
        MITModule *aModule = [self.notifications objectAtIndex:indexPath.row];
        cell.textLabel.text = aModule.longName;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView.tag = indexPath.row;
        [((UISwitch *)(cell.accessoryView)) setOn:aModule.pushNotificationEnabled];
    } else if (indexPath.section == SERVER_SECTION_INDEX) {
        cell = [tableView dequeueReusableCellWithIdentifier:AdvancedCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:AdvancedCellIdentifier] autorelease];
            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
        }
        
        NSArray *serverNames = MITMobileWebGetAPIServerList();
        cell.textLabel.text = [[serverNames objectAtIndex:indexPath.row] host];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (_selectedRow == NSUIntegerMax) {
            NSURL *server = MITMobileWebGetCurrentServerURL();
            NSArray *serverList = MITMobileWebGetAPIServerList();
            _selectedRow = [serverList indexOfObject:server];
        }
        
        cell.accessoryType = (_selectedRow == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SERVER_SECTION_INDEX) {
        if (indexPath.row != _selectedRow) {
            NSUInteger oldRow = _selectedRow;
            _selectedRow = indexPath.row;
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:SERVER_SECTION_INDEX]
                     withRowAnimation:UITableViewRowAnimationNone];
            [self serverSelectionDidChangeFrom:oldRow
                                            to:_selectedRow];
        }
    }
}

/*!
 @method serverSelectionDidChangeFrom:to:
 @abstract Changes the server that push notifications are recieved from
 @param old the name of the old server. Should be a key in [MITMobileWebAPI APIServers].
 @param new the ID of the new server for push notifications. Should be a key in [MITMobileWebAPI APIServers].
*/
- (void)serverSelectionDidChangeFrom:(NSInteger)old to:(NSInteger)new {
    // Disable any active notifications on the first pass.
    // The entire process could 
    for (MITModule *module in self.notifications) {
        if (module.pushNotificationEnabled) {
            [self performPushConfigurationForModule:module.tag
                                            enabled:NO];
        }
    }
    
    /* bskinner
    * ToDo: See if there is a better way to do this.
    * At the moment, if multiple requests for a single module are
    *  sent, then any in-flight requests will be aborted before
    *  sending a new request. This forces the code to wait
    *  until ALL requests to the current server have completed
    *  before sending registration requests to the new server.
    */
    while([self numberOfActiveRequests] > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    }
    
    NSArray *server = MITMobileWebGetAPIServerList();
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MITDeviceIdKey];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    
    MITMobileWebSetCurrentServerURL([server objectAtIndex:new]);
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    for (MITModule *module in self.notifications) {
        if (module.pushNotificationEnabled) {
            [self performPushConfigurationForModule:module.tag
                                            enabled:YES];
        }
    }
}

- (void)switchDidToggle:(id)sender {
    UISwitch *aSwitch = sender;
    MITModule *aModule = [self.notifications objectAtIndex:aSwitch.tag];
    
    [self performPushConfigurationForModule:aModule.tag
                                    enabled:aSwitch.isOn];
}

- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled
{
    NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
    [parameters setObject:tag
                   forKey:@"module_name"];
    [parameters setObject:(enabled) ? @"1" : @"0"
                   forKey:@"enabled"];
    
    MITMobileWebAPI *existingRequest = [self requestWithTag:tag];
    if (existingRequest != nil) {
        [existingRequest abortRequest];
        [self removeRequestWithTag:tag];
    }
    
    MITMobileWebAPI *request = [MITMobileWebAPI jsonLoadedDelegate:self];
    [self addRequest:request
             withTag:tag];
    [request requestObjectFromModule:@"push"
                             command:@"moduleSetting"
                          parameters:parameters];
}

- (void) reloadSettings {
	[self.tableView reloadData];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	if (object && [object isKindOfClass:[NSDictionary class]] && [object objectForKey:@"success"]) {
        MITMobileWebAPI *aRequest = [self requestWithTag:request.userData];
        
        if (aRequest) {
            // this backwards finding would be a lot simpler if 
            // the backend would just return module and enabled status
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            MITModule *module = [appDelegate moduleForTag:aRequest.userData];
            
            NSUInteger tag = [self.notifications indexOfObject:module];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag
                                                        inSection:0];
            [indexPath indexPathByAddingIndex:tag];
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
            [module setPushNotificationEnabled: aSwitch.isOn];
            [self removeRequestWithTag: aRequest.userData];
        }
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    [self removeRequestWithTag:request.userData];
	[self reloadSettings];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    DLog(@"%@",[error localizedDescription]);
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Settings";
}

- (void)addRequest:(MITMobileWebAPI*)request
           withTag:(NSString*)tag
{
    dispatch_async(_requestQueue, ^(void) {
        if ([self.apiRequests objectForKey:tag] == nil) {
            request.userData = tag;
            [self.apiRequests setObject:request
                                 forKey:tag];
        } else {
            NSLog(@"Error: attempting to overwrite in-flight request with tag %@",tag);
        }
    });
}

- (MITMobileWebAPI*)requestWithTag:(NSString*)tag {
    __block MITMobileWebAPI *request = nil;
    
    dispatch_sync(_requestQueue, ^(void) {
        request = [self.apiRequests objectForKey:tag];
    });
    
    return request;
}

- (void)removeRequestWithTag:(NSString*)tag {
    dispatch_async(_requestQueue, ^(void) {
        [self.apiRequests removeObjectForKey:tag];
    });
}

- (NSUInteger)numberOfActiveRequests {
    __block NSUInteger requestCount = 0;
    
    dispatch_sync(_requestQueue, ^(void) {
        requestCount = [self.apiRequests count];
    });
    
    return requestCount;
}

@end

