#import <Foundation/Foundation.h>

#import "MITUnreadNotifications.h"

@class MIT_MobileAppDelegate;

@interface MITModule : NSObject {

    NSString *tag; // Internal module name. Never displayed to user.
    NSString *shortName; // The name to be displayed in the UITabBar's first 4 tabBarItems
    NSString *longName; // The name to be displayed in the rows of the More table of the UITabBar
    
    NSString *iconName; // Filename of module artwork. The foo in "Resources/Modules/foo.png".
    
    // The root UIViewController for a module's tab is always a 
    // UINavigationController. This is because any tab reached via the More 
    // tab is automatically wrapped in a UINavigationController anyway, and a 
    // consistent experience is important to this application. Note that when 
    // reached via the More tab, a module's views temporarily become 
    // children of the UITabBarController's moreNavigationController. This can 
    // lead to seemingly ignored messages like when changing a module's 
    // tabBarItem.badgeValue, because they are actually affecting the 
    // moreNavigationController. There will be more changes to MITModule later 
    // to simplify tab badging and navigation stack management.
    UINavigationController *tabNavController;
    
    BOOL isMovableTab; // TRUE if this module's tab can be rearranged during UITabBar customization. FALSE otherwise.
    BOOL canBecomeDefault; // TRUE if this module can become the default tab at startup
    BOOL pushNotificationSupported;
    BOOL pushNotificationEnabled; // toggled by user in SettingsModule
}

#pragma mark Required methods (must override in subclass)

- (id)init; // Basic settings: name, icon, root view controller. Keep this minimal. Anything time-consuming needs to be asynchronous.

#pragma mark Optional methods

- (void)applicationDidFinishLaunching; // Called after all modules are initialized and have added their tabNavController to the tab bar

- (void)applicationWillTerminate; // Called before app quits. Last chance to save state.

- (NSString *)description; // what NSLog(@"%@", aModule); prints

- (void)didAppear;

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query;

- (BOOL)handleNotification: (MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen; // Called when a push notification arrives

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications; // called to let the module know the unreads may have changed

- (void)becomeActiveTab;

- (BOOL)isActiveTab;

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *longName;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, readonly) UINavigationController *tabNavController;
@property (nonatomic, assign) BOOL isMovableTab;
@property (nonatomic, assign) BOOL canBecomeDefault;
@property (nonatomic, assign) BOOL pushNotificationSupported;
@property (nonatomic, assign) BOOL pushNotificationEnabled;

@property (nonatomic, retain) NSString *badgeValue;          // What appears in the red bubble in the module's tab. Set to nil to make it disappear. Will eventually show in the More tab's table as well.
@property (nonatomic, readonly) UIImage *icon;       // The icon used for the More tab's table (color)
@property (nonatomic, readonly) UIImage *tabBarIcon; // The icon used for the UITabBar (black and white)

@end
