#import "MITModule.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"

@interface EmergencyModule : MITModule <EmergencyViewControllerDelegate> {
    EmergencyViewController *mainViewController;
	BOOL emergencyMessageLoaded;
}

- (void)didReceiveNewEmergencyInfo:(NSNotification *)aNotification;

- (void)syncUnreadNotifications;

- (void)infoDidLoad:(id)object;

@property (readwrite, retain) EmergencyViewController *mainViewController;

@end
