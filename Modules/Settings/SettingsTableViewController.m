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
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

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
@property (nonatomic) BOOL canRegisterForNotifications;

- (void)didRecognizeAdvancedSettingsGesture:(UIGestureRecognizer*)gesture;
- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled;
- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled completed:(void (^)(void))block;
- (void)switchDidToggle:(id)sender;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";

    self.tableView.backgroundView = nil;

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
                              @{MITSettingsSectionTitleKey : @"",
                                MITSettingsSectionDetailKey : @"Touchstone is MIT's single sign-on authentication service.",
                                MITSettingsCellIdentifierKey : @"MITSettingsCellIdentifierTouchstone"},
                              @{MITSettingsSectionTitleKey : @"API Server",
                                MITSettingsCellIdentifierKey : @"MITSettingsCellIdentifierAPIServer"}];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey]) {
        self.canRegisterForNotifications = YES;
    }

    if (self.advancedSettingsAreVisible) {
        // Reload the server table just in case it was changed outside the settings
        // module
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITSettingsSectionServers]
                      withRowAnimation:UITableViewRowAnimationNone];
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
    self.canRegisterForNotifications = NO;
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sectionsMetadata[section][MITSettingsSectionTitleKey];
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

        cell.textLabel.text = aModule.title;

        UISwitch *switchView = (UISwitch*)cell.accessoryView;
        switchView.tag = indexPath.row;

        if (self.canRegisterForNotifications) {
            //[switchView setOn:aModule.pushNotificationEnabled
            //         animated:NO];
        } else {
            switchView.enabled = NO;
           //aModule.pushNotificationEnabled = NO;
        }
    } else if (MITSettingsSectionTouchstone == indexPath.section) {
        cell.textLabel.text = @"Touchstone Settings";
    } else if (MITSettingsSectionServers == indexPath.section) {
        NSArray *servers = MITMobileWebGetAPIServerList();
        cell.textLabel.text = [servers[indexPath.row] host];

        NSURL *currentServer = MITMobileWebGetCurrentServerURL();
        cell.accessoryView = nil;
        if ([servers indexOfObject:currentServer] == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (void)setCanRegisterForNotifications:(BOOL)canRegisterForNotifications
{
    if (_canRegisterForNotifications != canRegisterForNotifications) {
        _canRegisterForNotifications = canRegisterForNotifications;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITSettingsSectionNotifications]
                      withRowAnimation:UITableViewRowAnimationNone];
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
        NSArray *serverURLs = MITMobileWebGetAPIServerList();
        
        if ([serverURLs[indexPath.row] isEqual:MITMobileWebGetCurrentServerURL()]) {
            // If the URL is already set to the correct one, just return
            return;
        }
        
        // TODO: re-evaluate where this functionality belongs. It doesn't feel right
        // to be handling the low-level notification config in a view controller

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.accessoryType != UITableViewCellAccessoryCheckmark) {
            UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [indicatorView startAnimating];

            cell.accessoryView = indicatorView;
        }

        NSMutableDictionary *notificationStates = [[NSMutableDictionary alloc] init];
        [self.notifications enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
            // Save the currently enabled state for the module. We will be using this data
            // to reset the state after switching the API server
            //notificationStates[module.tag] = @(module.pushNotificationEnabled);
            [self performPushConfigurationForModule:module.name
                                            enabled:NO];
        }];

        NSUInteger previousServerIndex = [serverURLs indexOfObject:MITMobileWebGetCurrentServerURL()];
        MITMobileWebSetCurrentServerURL(serverURLs[indexPath.row]);

        NSData *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
        [MITDeviceRegistration registerDeviceWithToken:deviceToken
                                            registered:^(MITIdentity *identity, NSError *error) {
                                                if (error || !identity) {
                                                    self.canRegisterForNotifications = NO;
                                                } else {
                                                    NSArray *moduleTags = [notificationStates allKeys];
                                                    [moduleTags enumerateObjectsUsingBlock:^(NSString *moduleTag, NSUInteger idx, BOOL *stop) {
                                                        BOOL enabled = [notificationStates[moduleTag] boolValue];
                                                        
                                                        [self performPushConfigurationForModule:moduleTag
                                                                                        enabled:enabled
                                                                                      completed:^{
                                                                                          // If we are sending out the last request, refresh the whole section
                                                                                          if (idx == ([moduleTags count] - 1)) {
                                                                                              NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:previousServerIndex inSection:MITSettingsSectionServers];
                                                                                              [tableView reloadRowsAtIndexPaths:@[previousIndexPath,indexPath]
                                                                                                               withRowAnimation:UITableViewRowAnimationNone];
                                                                                          }
                                                                                      }];
                                                        
                                                    }];
                                                }
                                            }];
    }
}

- (void)switchDidToggle:(id)sender {
    UISwitch *aSwitch = sender;
    MITModule *aModule = self.notifications[aSwitch.tag];

    [self performPushConfigurationForModule:aModule.name
                                    enabled:[aSwitch isOn]];
}


- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled
{
    [self performPushConfigurationForModule:tag enabled:enabled completed:nil];
}

- (void)performPushConfigurationForModule:(NSString*)tag enabled:(BOOL)enabled completed:(void (^)(void))block
{
    // If we don't have an identity, don't even try to enable (or disable) notifications,
    // just leave everything as-is
    if (!self.canRegisterForNotifications) {
        if (block) {
            block();
        }

        return;
    } else {
        MITModule *module = [MITAppDelegate() moduleWithTag:tag];
        NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
        parameters[@"module_name"] = tag;
        parameters[@"enabled"] = (enabled ? @"1" : @"0");

        NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"moduleSetting" parameters:parameters];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

        requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *jsonResult, NSString *contentType, NSError *error) {
            if (![jsonResult isKindOfClass:[NSDictionary class]]) {
                DDLogError(@"fatal error: invalid response for push configuration");
            } else if ([jsonResult[@"success"] boolValue]) {
               // module.pushNotificationEnabled = [jsonResult[@"enabled"] boolValue];
            } else {
                if (error) {
                    [UIAlertView alertViewForError:error withTitle:@"Settings" alertViewDelegate:nil];
                } else if (jsonResult[@"error"]) {
                    DDLogError(@"%@ notifications change request failed: %@",tag,error);
                }
            }

            if (block) {
                block();
            }
        };
        
        [[NSOperationQueue mainQueue] addOperation:requestOperation];
    }
}

@end
