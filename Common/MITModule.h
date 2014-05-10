#import <Foundation/Foundation.h>

#import "MITUnreadNotifications.h"

@class MIT_MobileAppDelegate;

@interface MITModule : NSObject
@property (nonatomic,weak) UIViewController *homeViewController;
@property (nonatomic,weak) UIViewController *summaryViewController;

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIImage *icons;

@property (nonatomic, assign) BOOL pushNotificationEnabled;

// Older properties, no longer used.
@property (nonatomic,readonly) BOOL isLoaded DEPRECATED_ATTRIBUTE;

@property (nonatomic, strong) UIViewController *moduleHomeController DEPRECATED_ATTRIBUTE;
@property (nonatomic, copy) NSString *shortName DEPRECATED_ATTRIBUTE;
@property (nonatomic, copy) NSString *longName DEPRECATED_ATTRIBUTE;
@property (nonatomic, copy) NSString *iconName DEPRECATED_ATTRIBUTE;
@property (nonatomic, assign) BOOL pushNotificationSupported DEPRECATED_ATTRIBUTE;

@property (nonatomic, retain) NSString *badgeValue DEPRECATED_ATTRIBUTE;          // What appears in the red bubble in the module's tab. Set to nil to make it disappear. Will eventually show in the More tab's table as well.
@property (nonatomic, readonly) UIImage *springboardIcon DEPRECATED_ATTRIBUTE;

@property (nonatomic) BOOL hasLaunchedBegun DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString *currentPath DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString *currentQuery DEPRECATED_ATTRIBUTE;

#pragma mark Required methods (must override in subclass)
- (instancetype)initWithTag:(NSString*)tag;
- (instancetype)init;

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom;
- (UIViewController*)homeViewControllerForUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom;
- (UIViewController*)createHomeViewControllerForPadIdiom;
- (UIViewController*)createHomeViewControllerForPhoneIdiom;

#pragma mark Optional methods
- (void)applicationDidFinishLaunching DEPRECATED_ATTRIBUTE; // Called after all modules are initialized and have added their tabNavController to the tab bar
- (void)applicationWillTerminate DEPRECATED_ATTRIBUTE; // Called before app quits. Last chance to save state.
- (void)applicationDidEnterBackground DEPRECATED_ATTRIBUTE;
- (void)applicationWillEnterForeground DEPRECATED_ATTRIBUTE;

- (void)didAppear DEPRECATED_ATTRIBUTE;
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query DEPRECATED_ATTRIBUTE;
- (void)resetURL DEPRECATED_ATTRIBUTE; // reset the URL, (i.e. path and query to empty strings)

- (BOOL)handleNotification:(MITNotification *)notification shouldOpen:(BOOL)shouldOpen; // Called when a push notification arrives
- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications; // called to let the module know the unreads may have changed
@end
