#import "MITModule.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"

@interface EmergencyModule : MITModule <EmergencyViewControllerDelegate>
@property (weak) EmergencyViewController *mainViewController;
@property BOOL didReadMessage;

- (void)syncUnreadNotifications;
@end
