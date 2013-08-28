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
#import "MobileRequestOperation.h"

NSString * const MITSettingsSectionTitleKey = @"MITSettingsSectionTitle";
NSString * const MITSettingsSectionDetailKey = @"MITSettingsSectionDetail";
NSString * const MITSettingsCellIdentifierKey = @"MITSettingsCellIdentifier";

enum {
    MITSettingsSectionNotifications = 0,
    MITSettingsSectionTouchstone,
    MITSettingsSectionServers
};

@interface SettingsTableViewController ()
@property (copy) NSArray *sectionsMetadata;
@property BOOL advancedSettingsAreVisible;

- (void)didRecognizeAdvancedSettingsGesture:(UIGestureRecognizer*)gesture;
- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled;
- (void)switchDidToggle:(id)sender;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";

    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.784
                                                     green:0.792
                                                      blue:0.812
                                                     alpha:1.0];

    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.notifications = [appDelegate.modules filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pushNotificationSupported == TRUE"]];

    UISwipeGestureRecognizer *showGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(didRecognizeAdvancedSettingsGesture:)];
    showGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    showGesture.numberOfTouchesRequired = 2;
    [self.tableView addGestureRecognizer:showGesture];

    self.sectionsMetadata = @[@{MITSettingsSectionTitleKey : @"Notifications",
                                MITSettingsSectionDetailKey : @"Turn off Notifications to disable alerts for that module.",
                                MITSettingsCellIdentifierKey : @"MITSettingsCellIdentifierNotifications"},
                              @{MITSettingsSectionTitleKey : @"Touchstone",
                                MITSettingsSectionDetailKey : @"Touchstone is MIT's single sign-on authentication service.",
                                MITSettingsCellIdentifierKey : @"MITSettingsCellIdentifierTouchstone"},
                              @{MITSettingsSectionTitleKey : @"Application Server",
                                MITSettingsCellIdentifierKey : @"MITSettingsCellIdentifierAPIServer"}];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.advancedSettingsAreVisible) {
    // Reload the server table just in case it was changed outside the settings
    // module
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITSettingsSectionServers]
                      withRowAnimation:UITableViewRowAnimationRight];
    }
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

- (void)viewDidUnload {
    [super viewDidUnload];
    self.advancedSettingsAreVisible = NO;
}

#pragma mark Advanced view methods
- (void)didRecognizeAdvancedSettingsGesture:(UIGestureRecognizer*)gesture
{
    UISwipeGestureRecognizer *swipeGesture = (UISwipeGestureRecognizer*)gesture;

    if (self.advancedSettingsAreVisible) {
        swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        self.advancedSettingsAreVisible = NO;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:MITSettingsSectionServers]
                      withRowAnimation:UITableViewRowAnimationRight];
    } else {
        swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        self.advancedSettingsAreVisible = YES;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:MITSettingsSectionServers]
                      withRowAnimation:UITableViewRowAnimationRight];
    }
}


#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.advancedSettingsAreVisible) {
        return 3;
    } else {
        return 2; // Notifications & Touchstone
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MITSettingsSectionNotifications:
            return [self.notifications count];
        
        case MITSettingsSectionTouchstone:
            return 1;
            
        case MITSettingsSectionServers:
            return [MITMobileWebGetAPIServerList() count];
        
        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *text = self.sectionsMetadata[section][MITSettingsSectionTitleKey];
    
    if ([text length]) {
        return [UITableView groupedSectionHeaderWithTitle:text];
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return GROUPED_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *text = self.sectionsMetadata[section][MITSettingsSectionDetailKey];
    
    if ([text length]) {
        ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
        footerLabel.text = text;
        return footerLabel;
    } else {
        return nil;
    }
}

- (CGFloat)tableView: (UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString *text = self.sectionsMetadata[section][MITSettingsSectionDetailKey];

    if ([text length]) {
        return [ExplanatorySectionLabel heightWithText:text
                                                 width:CGRectGetWidth(self.tableView.bounds)
                                                  type:ExplanatorySectionFooter];
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = self.sectionsMetadata[indexPath.section][MITSettingsCellIdentifierKey];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        switch (indexPath.section) {
            case MITSettingsSectionNotifications: {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];

                cell.accessoryType = UITableViewCellAccessoryNone;
                UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
                [aSwitch addTarget:self action:@selector(switchDidToggle:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = aSwitch;

                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                break;
            }
                
            case MITSettingsSectionTouchstone: {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.backgroundColor = [UIColor clearColor];

                break;
            }
                
            case MITSettingsSectionServers: {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
                cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.backgroundColor = [UIColor clearColor];

                break;
            }
                
            default:
                return nil;
        }
    }

    [self configureCell:cell
            atIndexPath:indexPath
           forTableView:tableView];

    return cell;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath forTableView:(UITableView*)tableView
{
    if (MITSettingsSectionNotifications == indexPath.section) {
        MITModule *aModule = self.notifications[indexPath.row];

        cell.textLabel.text = aModule.longName;

        UISwitch *switchView = (UISwitch*)cell.accessoryView;
        switchView.tag = indexPath.row;

        if (![MITDeviceRegistration identity]) {
            switchView.enabled = NO;
            aModule.pushNotificationEnabled = NO;
        } else {
            [switchView setOn:aModule.pushNotificationEnabled
                     animated:YES];
        }
    } else if (MITSettingsSectionTouchstone == indexPath.section) {
        cell.textLabel.text = @"Touchstone Settings";
    } else if (MITSettingsSectionServers == indexPath.section) {
        NSURL *currentServer = MITMobileWebGetCurrentServerURL();
        NSArray *servers = MITMobileWebGetAPIServerList();

        cell.textLabel.text = [servers[indexPath.row] host];

        if ([servers indexOfObject:currentServer] == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (MITSettingsSectionTouchstone == indexPath.section) {
        SettingsTouchstoneViewController *touchstoneSettings = [[SettingsTouchstoneViewController alloc] init];
        [self.navigationController pushViewController:touchstoneSettings
                                             animated:YES];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    } else if (MITSettingsSectionServers == indexPath.section) {
        NSMutableDictionary *notificationStates = [[NSMutableDictionary alloc] init];
        NSArray *serverURLs = MITMobileWebGetAPIServerList();
        NSURL *serverURL = serverURLs[indexPath.row];

        [self.notifications enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
            notificationStates[module.tag] = @(module.pushNotificationEnabled);
            [self performPushConfigurationForModule:module.tag
                                            enabled:NO];
        }];

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MITDeviceIdKey];
        MITMobileWebSetCurrentServerURL(serverURL);

        [self.notifications enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
            [self performPushConfigurationForModule:module.tag
                                            enabled:[notificationStates[module.tag] boolValue]];

        }];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)switchDidToggle:(id)sender {
    UISwitch *aSwitch = sender;
    MITModule *aModule = self.notifications[aSwitch.tag];
    
    [self performPushConfigurationForModule:aModule.tag
                                    enabled:[aSwitch isOn]];
}

- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled
{
    // If we don't have an identity, don't even try to enable (or disable) notifications,
    // just leave everything as-is
    if (![MITDeviceRegistration identity]) {
        return;
    } else {
        __weak MITModule *module = [MITAppDelegate() moduleForTag:tag];
        NSUInteger moduleIndex = [self.notifications indexOfObject:module];

        NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
        parameters[@"module_name"] = tag;
        parameters[@"enabled"] = (enabled ? @"1" : @"0");
        
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"push"
                                                                                 command:@"moduleSetting"
                                                                              parameters:parameters];
        request.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *jsonResult, NSString *contentType, NSError *error) {
            if ([jsonResult[@"success"] boolValue]) {
                module.pushNotificationEnabled = [jsonResult[@"enabled"] boolValue];
            } else {
                if (error) {
                    [UIAlertView alertViewForError:error withTitle:@"Settings" alertViewDelegate:nil];
                } else if (jsonResult[@"error"]) {
                    DDLogError(@"%@ notifications change request failed: %@",tag,error);
                }
            }

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:moduleIndex inSection:MITSettingsSectionNotifications];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        };
        
        [[MobileRequestOperation defaultQueue] addOperation:request];
    }
}

@end


