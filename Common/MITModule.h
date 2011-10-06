#import <Foundation/Foundation.h>

#import "MITUnreadNotifications.h"

@class MIT_MobileAppDelegate;
@class SpringboardIcon;

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
    UINavigationController *tabNavController DEPRECATED_ATTRIBUTE;
    
    BOOL isMovableTab DEPRECATED_ATTRIBUTE; // TRUE if this module's tab can be rearranged during UITabBar customization. FALSE otherwise.
    BOOL canBecomeDefault DEPRECATED_ATTRIBUTE; // TRUE if this module can become the default tab at startup
    BOOL pushNotificationSupported;
    BOOL pushNotificationEnabled; // toggled by user in SettingsModule
	
	// properties used for saving and restoring state
	// if module keeps track of its state it is required respond to handleLocalPath:query
	BOOL hasLaunchedBegun; // keeps track of if the module has been opened at lease once, since application launch
	NSString *currentPath; // the path of the URL representing current module state
	NSString *currentQuery; // query of the URL representing current module state
    
    UIViewController* _moduleHomeController;
    SpringboardIcon *springboardButton;
}

#pragma mark Required methods (must override in subclass)

- (id)init; // Basic settings: name, icon, root view controller. Keep this minimal. Anything time-consuming needs to be asynchronous.
- (NSString *)description;

#pragma mark Optional methods

- (void)applicationDidFinishLaunching; // Called after all modules are initialized and have added their tabNavController to the tab bar
- (void)applicationWillTerminate; // Called before app quits. Last chance to save state.
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;

- (void)didAppear;
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query;
- (void)resetURL; // reset the URL, (i.e. path and query to empty strings)

- (BOOL)handleNotification:(MITNotification *)notification shouldOpen:(BOOL)shouldOpen; // Called when a push notification arrives
- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications; // called to let the module know the unreads may have changed

// This will push the moduleHomeController onto the
// navigation stack of it isn't already the top-most
// view controller.
- (void)becomeActiveModule;

#pragma mark tabNavController methods

- (void) popToRootViewController;
- (UIViewController *) rootViewController;

- (void) pushViewController: (UIViewController *)viewController;
- (UIViewController *) parentForViewController:(UIViewController *)viewController;




@property (nonatomic,readonly) BOOL isLoaded;

@property (nonatomic, readonly, retain) UIViewController *moduleHomeController;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *longName;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, assign) BOOL pushNotificationSupported;
@property (nonatomic, assign) BOOL pushNotificationEnabled;

@property (nonatomic, retain) NSString *badgeValue;          // What appears in the red bubble in the module's tab. Set to nil to make it disappear. Will eventually show in the More tab's table as well.
@property (nonatomic, readonly) UIImage *springboardIcon;
@property (nonatomic, retain) SpringboardIcon *springboardButton;

@property (nonatomic) BOOL hasLaunchedBegun;
@property (nonatomic, retain) NSString *currentPath;
@property (nonatomic, retain) NSString *currentQuery;

@end
