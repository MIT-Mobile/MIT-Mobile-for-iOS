#import "SettingsTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "ExplanatorySectionLabel.h"
#import "MITMobileServerConfiguration.h"
#import "MITDeviceRegistration.h"
#import "MITLogging.h"
#import "MobileKeychainServices.h"
#import "MITConstants.h"
#import "SettingsTouchstoneViewController.h"

NSString * const SettingsTitleString = @"Notifications";
NSString * const SettingsSubtitleString = @"Turn off Notifications to disable alerts for that module.";

NSString * const TouchstoneTitleString = @"MIT Touchstone";
NSString * const TouchstoneSubtitleString = @"Touchstone is MIT's single sign-on authentication service.";

NSString * const ServersTitleString = @"API Server";

#define TITLE_HEIGHT 20.0
#define SUBTITLE_HEIGHT NAVIGATION_BAR_HEIGHT
#define PADDING 10.0
#define PADDED_WIDTH(x) (floorf(x - PADDING))

enum {
    kSettingsNotificationSection = 0,
    kSettingsTouchstoneSection = 1,
    kSettingsServerSection = 2,
    kSettingsSectionCount
};

@interface SettingsTableViewController ()
@property (nonatomic,retain) UIGestureRecognizer* showServerListGesture;
@property (nonatomic,retain) UIGestureRecognizer* hideServerListGesture;

@property (nonatomic,retain) UITextField *touchstoneUsernameField;
@property (nonatomic,retain) UITextField *touchstonePasswordField;

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

@synthesize touchstoneUsernameField = _touchstoneUsernameField,
            touchstonePasswordField = _touchstonePasswordField;


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
    
    _requestQueue = dispatch_queue_create(NULL, NULL);
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSettingsTouchstoneSection]
                  withRowAnimation:UITableViewRowAnimationFade];
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
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kSettingsServerSection]
                      withRowAnimation:UITableViewRowAnimationFade];
    } else if (gesture == self.hideServerListGesture) {
        _advancedOptionsVisible = NO;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kSettingsServerSection]
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.view removeGestureRecognizer:self.hideServerListGesture];
        [self.view addGestureRecognizer:self.showServerListGesture];
    }
}


#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_advancedOptionsVisible) {
        return kSettingsSectionCount;
    } else {
        return kSettingsSectionCount - 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    switch (section) {
        case kSettingsNotificationSection:
            rows = [self.notifications count];
            break;
        
        case kSettingsTouchstoneSection:
            rows = 1;
            break;
            
        case kSettingsServerSection:
            rows = (_advancedOptionsVisible) ? [MITMobileWebGetAPIServerList() count] : 0;
            break;
        
        default:
            break;
    }
    
    return rows;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = nil;
    NSString *titleText = nil;
    
    switch(section) {
        case kSettingsNotificationSection:
            titleText = SettingsTitleString;
            break;
            
        case kSettingsTouchstoneSection:
            titleText = TouchstoneTitleString;
            break;
            
        case kSettingsServerSection: {
            if (_advancedOptionsVisible) {
                titleText = ServersTitleString;
            }
            break;
        }
    }
    
    if (titleText) {
        result = [UITableView groupedSectionHeaderWithTitle:titleText];
    }
    
    return result;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 0;
    
    switch(section) {
        case kSettingsNotificationSection:
        case kSettingsTouchstoneSection:
            height = GROUPED_SECTION_HEADER_HEIGHT;
            break;
            
        case kSettingsServerSection: {
            if (_advancedOptionsVisible) {
                height = GROUPED_SECTION_HEADER_HEIGHT;
            }
            break;
        }
    }
    
    return height;
}

- (UIView *) tableView: (UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *result = nil;
    NSString *subtitleText = nil;
    
    switch(section) {
        case kSettingsNotificationSection:
            subtitleText = SettingsSubtitleString;
            break;
        case kSettingsTouchstoneSection:
            subtitleText = TouchstoneSubtitleString;
            break;
    }
    
    if (subtitleText) {
        ExplanatorySectionLabel *footerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
        footerLabel.text = subtitleText;
        result = footerLabel;
    }
    
    return result;
}

- (CGFloat)tableView: (UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CGFloat height = 0;
    
    NSString *subtitleText = nil;
    
    switch(section) {
        case kSettingsNotificationSection:
            subtitleText = SettingsSubtitleString;
            break;
        case kSettingsTouchstoneSection:
            subtitleText = TouchstoneSubtitleString;
            break;
    }
    
    if (subtitleText) {
        height = [ExplanatorySectionLabel heightWithText:subtitleText 
                                                   width:self.view.frame.size.width 
                                                    type:ExplanatorySectionFooter];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *AdvancedCellIdentifier = @"AdvancedCell";
    static NSString *TouchstoneUsernameCellIdentifier = @"TouchstoneUsernameCell";
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case kSettingsNotificationSection:
        {
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
            
            break;
        }
            
        case kSettingsTouchstoneSection:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:TouchstoneUsernameCellIdentifier];
                    if (cell == nil)
                    {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:TouchstoneUsernameCellIdentifier] autorelease];
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                        
                        cell.textLabel.backgroundColor = [UIColor clearColor];
                    }
                    
                    cell.textLabel.text = @"Touchstone Settings";
                    break;
                }
            }
            break;
        }
            
        case kSettingsServerSection:
        {
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
            
            break;
        }
            
        default:
            cell = nil;
    }
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSettingsServerSection)
    {
        if (indexPath.row != _selectedRow)
        {
            NSUInteger oldRow = _selectedRow;
            _selectedRow = indexPath.row;
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:kSettingsServerSection]
                     withRowAnimation:UITableViewRowAnimationNone];
            [self serverSelectionDidChangeFrom:oldRow
                                            to:_selectedRow];
        }
    }
    else if (indexPath.section == kSettingsTouchstoneSection)
    {
        SettingsTouchstoneViewController *vc = [[[SettingsTouchstoneViewController alloc] init] autorelease];
        [self.navigationController pushViewController:vc
                                                     animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
            ELog(@"Error: attempting to overwrite in-flight request with tag %@",tag);
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

