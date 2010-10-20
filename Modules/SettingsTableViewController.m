#import "SettingsTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"

NSString * const SectionTitleString = @"Notifications";
NSString * const SectionSubtitleString = @"Turn off Notifications to disable alerts for that module.";
#define TITLE_HEIGHT 20.0
#define SUBTITLE_HEIGHT 44.0
#define PADDING 10.0

@implementation SettingsTableViewController

@synthesize notifications;
@synthesize apiRequests;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView applyStandardColors];
	self.apiRequests = [[NSMutableDictionary alloc] initWithCapacity:1];

    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.notifications = [appDelegate.modules filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pushNotificationSupported == TRUE"]];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    self.notifications = nil;
}

- (void)dealloc {
    [super dealloc];
	[self.apiRequests release];
    self.notifications = nil;
}


#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    switch (section) {
        case 0:
            rows = [notifications count];
            break;
        default:
            rows = 0;
            break;
    }
    return rows;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *result = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, SUBTITLE_HEIGHT + TITLE_HEIGHT)] autorelease];
	
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, 200, TITLE_HEIGHT)];
	titleView.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	titleView.textColor = GROUPED_SECTION_FONT_COLOR;
	titleView.backgroundColor = [UIColor clearColor];
	titleView.text = SectionTitleString;
					  
	UILabel *subtitleView = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, round(TITLE_HEIGHT + 1.5 * PADDING), round(tableView.frame.size.width-2 * PADDING), SUBTITLE_HEIGHT)];
	subtitleView.numberOfLines = 0;
	subtitleView.backgroundColor = [UIColor clearColor];
	subtitleView.lineBreakMode = UILineBreakModeWordWrap;
	subtitleView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	subtitleView.text = SectionSubtitleString;
	
	[result addSubview:titleView];
	[titleView release];
	[result addSubview:subtitleView];
	[subtitleView release];
	return result;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return SUBTITLE_HEIGHT + TITLE_HEIGHT + 2.5 * PADDING;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = aSwitch;
        [aSwitch addTarget:self action:@selector(switchDidToggle:) forControlEvents:UIControlEventValueChanged];
        [aSwitch release];
        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    }
    
    MITModule *aModule = [self.notifications objectAtIndex:indexPath.row];
	NSString *label = nil;
    
    switch (indexPath.section) {
        case 0:
			label = aModule.longName;
            break;
        default:
            break;
    }
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = label;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView.tag = indexPath.row;
	[((UISwitch *)(cell.accessoryView)) setOn:aModule.pushNotificationEnabled];
    
    return cell;    
}

- (void)switchDidToggle:(id)sender {
    UISwitch *aSwitch = sender;
    MITModule *aModule = [notifications objectAtIndex:aSwitch.tag];
    NSString *moduleTag = aModule.tag;
    
	NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
	[parameters setObject:moduleTag forKey:@"module_name"];
	NSString *enabledString = aSwitch.on ? @"1" : @"0";
	[parameters setObject:enabledString forKey:@"enabled"];
	
	MITMobileWebAPI *existingRequest = [apiRequests objectForKey:moduleTag];
	if (existingRequest != nil) {
		[existingRequest abortRequest];
		[apiRequests removeObjectForKey:moduleTag];
	}
	MITMobileWebAPI *request = [MITMobileWebAPI jsonLoadedDelegate:self];
	[request requestObjectFromModule:@"push" command:@"moduleSetting" parameters:parameters];
	[apiRequests setObject:request forKey:moduleTag];
}

- (void) reloadSettings {
	[self.tableView reloadData];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	if (object && [object isKindOfClass:[NSDictionary class]] && [object objectForKey:@"success"]) {
		for (id moduleTag in apiRequests) {
			MITMobileWebAPI *aRequest = [apiRequests objectForKey:moduleTag];
			if (aRequest == request) {
				// this backwards finding would be a lot simpler if 
				// the backend would just return module and enabled status
				MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
				MITModule *module = [appDelegate moduleForTag:moduleTag];
				NSUInteger tag = [notifications indexOfObject:module];
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag inSection:0];
				[indexPath indexPathByAddingIndex:tag];
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
				UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
				BOOL enabled = aSwitch.on;
				[module setPushNotificationEnabled:enabled];
				
				[apiRequests removeObjectForKey:moduleTag];
				break;
			}
		}
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	for (id moduleTag in apiRequests) {
		MITMobileWebAPI *aRequest = [apiRequests objectForKey:moduleTag];
		if (aRequest == request) {
			[apiRequests removeObjectForKey:moduleTag];
			break;
		}
	}
	
	//for (MITModule *aModule in notifications) {
	//	NSLog(@"%@ %@", [aModule description], aModule.pushNotificationEnabled ? @"yes" : @"no");
	//}
	
	[self reloadSettings];
	
	UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:@"Connection Failure"
                              message:@"Failed to update your settings please try again later" 
                              delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

@end

