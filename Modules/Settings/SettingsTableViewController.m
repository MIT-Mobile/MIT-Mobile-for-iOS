#import "SettingsTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MITMobileServerConfiguration.h"

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
@end

@implementation SettingsTableViewController

@synthesize notifications = _notifications;
@synthesize apiRequests = _apiRequests;
@synthesize showServerListGesture = _showAdvancedGesture;
@synthesize hideServerListGesture = _hideAdvancedGesture;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    
    [self.tableView applyStandardColors];
	self.apiRequests = [[NSMutableDictionary alloc] initWithCapacity:1];

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

- (void)dealloc {
	self.apiRequests = nil;
    self.notifications = nil;
    self.showServerListGesture = nil;
    self.hideServerListGesture = nil;
    [super dealloc];
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
    while([self.apiRequests count] > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    }
    
    NSArray *server = MITMobileWebGetAPIServerList();
    MITMobileWebSetCurrentServerURL([server objectAtIndex:new]);
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
     
     /*
    NSString *moduleTag = aModule.tag;
	NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
	[parameters setObject:moduleTag forKey:@"module_name"];
	NSString *enabledString = aSwitch.on ? @"1" : @"0";
	[parameters setObject:enabledString forKey:@"enabled"];
	
	MITMobileWebAPI *existingRequest = [self.apiRequests objectForKey:moduleTag];
	if (existingRequest != nil) {
		[existingRequest abortRequest];
		[self.apiRequests removeObjectForKey:moduleTag];
	}
	MITMobileWebAPI *request = [MITMobileWebAPI jsonLoadedDelegate:self];
	[request requestObjectFromModule:@"push" command:@"moduleSetting" parameters:parameters];
	[self.apiRequests setObject:request forKey:moduleTag];
    */
}

- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled
{
    NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
    [parameters setObject:tag
                   forKey:@"module_name"];
    [parameters setObject:(enabled) ? @"1" : @"0"
                   forKey:@"enabled"];
    
    MITMobileWebAPI *existingRequest = [self.apiRequests objectForKey:tag];
    if (existingRequest != nil) {
        [existingRequest abortRequest];
        [self.apiRequests removeObjectForKey:tag];
    }
    MITMobileWebAPI *request = [MITMobileWebAPI jsonLoadedDelegate:self];
    [request requestObjectFromModule:@"push" command:@"moduleSetting" parameters:parameters];
    [self.apiRequests setObject:request forKey:tag];
}

- (void) reloadSettings {
	[self.tableView reloadData];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	if (object && [object isKindOfClass:[NSDictionary class]] && [object objectForKey:@"success"]) {
		for (id moduleTag in self.apiRequests) {
			MITMobileWebAPI *aRequest = [self.apiRequests objectForKey:moduleTag];
			if (aRequest == request) {
				// this backwards finding would be a lot simpler if 
				// the backend would just return module and enabled status
				MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
				MITModule *module = [appDelegate moduleForTag:moduleTag];
				NSUInteger tag = [self.notifications indexOfObject:module];
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag inSection:0];
				[indexPath indexPathByAddingIndex:tag];
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
				UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
				BOOL enabled = aSwitch.isOn;
				[module setPushNotificationEnabled:enabled];
				
                // FIXME: Don't mutate a container while enumerating it!
				[self.apiRequests removeObjectForKey:moduleTag];
				break;
			}
		}
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    for (id moduleTag in self.apiRequests) {
		MITMobileWebAPI *aRequest = [self.apiRequests objectForKey:moduleTag];
		if (aRequest == request) {
            // FIXME: Don't mutate a container while enumerating it!
			[self.apiRequests removeObjectForKey:moduleTag];
			break;
		}
	}
	
	//for (MITModule *aModule in notifications) {
	//	NSLog(@"%@ %@", [aModule description], aModule.pushNotificationEnabled ? @"yes" : @"no");
	//}
	
	[self reloadSettings];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return YES;
}

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Settings";
}

@end

