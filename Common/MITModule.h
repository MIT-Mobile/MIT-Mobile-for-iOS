#import <Foundation/Foundation.h>

#import "MITUnreadNotifications.h"

@class MIT_MobileAppDelegate;

@interface MITModule : NSObject
@property (nonatomic,readonly,weak) UIViewController *homeViewController;

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *longName;
@property (nonatomic,readonly) UIImage *springboardIcon;

@property (nonatomic, assign) BOOL pushNotificationEnabled;
@property (nonatomic, assign) BOOL pushNotificationSupported;


@property (nonatomic,readonly) BOOL isLoaded DEPRECATED_ATTRIBUTE;

@property (nonatomic, strong) UIViewController *moduleHomeController DEPRECATED_ATTRIBUTE;
@property (nonatomic, copy) NSString *iconName DEPRECATED_ATTRIBUTE;

@property (nonatomic, retain) NSString *badgeValue DEPRECATED_ATTRIBUTE;          // What appears in the red bubble in the module's tab. Set to nil to make it disappear. Will eventually show in the More tab's table as well.

@property (nonatomic) BOOL hasLaunchedBegun DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString *currentPath DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString *currentQuery DEPRECATED_ATTRIBUTE;

#pragma mark Required methods (must override in subclass)
- (instancetype)initWithTag:(NSString*)tag;

#pragma mark iDevice support
/** Indicates support for a specific user interface idiom.
 *  Returns 'NO' by default.
 *
 *  In order to support existing modules, if the module subclass
 *  responds to loadModuleHomeController and the current interface idiom is
 *  equal to UIUserInterfaceIdiomPhone, then this method will return YES.
 *  This behavior should be considered deprecated.
 *
 * @return YES if the passes idiom is supported.
 * @see UIUserInterfaceIdiom
 */
- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom;

- (UIViewController*)homeViewControllerForUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom;

/** Create an iPad compatible home view controller for the module.
 */
- (UIViewController*)createHomeViewControllerForPadIdiom;


/** Create an iPad compatible home view controller for the module.
 *
 *  In order to support existing modules, if the module subclass
 *  responds to loadModuleHomeController, it and the other moduleHomeController
 *  methods will be used to create and manage the view controller.
 *  This behavior should be considered deprecated.
 *
 * @related homeViewControllerForUserInterfaceIdiom:
 * @see createHomeViewControllerForPadIdiom
 */
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
@end
