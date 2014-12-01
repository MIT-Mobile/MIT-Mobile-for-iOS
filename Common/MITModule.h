#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MITModuleItem;

@interface MITModule : NSObject
@property(nonatomic,readonly,copy) NSString *name;
@property(nonatomic,readonly,copy) NSString *title;
@property(nonatomic,copy) NSString *longTitle;

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,copy) NSString *imageName;
@property(nonatomic,readonly) BOOL pushNotificationSupported;

@property(nonatomic,strong) IBOutlet UIViewController *viewController;

- (instancetype)initWithName:(NSString*)name title:(NSString*)title;

/*! Returns YES if the current user interface idiom is supported.
 */
- (BOOL)supportsCurrentUserInterfaceIdiom;

/*! Returns YES if the view controller has been loaded.
 * Calling this method does not invoke the autoloading.
 */
- (BOOL)isViewControllerLoaded;

/*! Creates the primary module's view controller.
 *  This method should never be called directly. This method will be called
 *  by the module when the primary view controller is requested but is currently
 *  set to nil. This method creates or loads a UIViewController and assigns it
 *  to the view controller property. By default, a UIViewController with an
 *  empty UIView will be created.
 */
- (void)loadViewController;

/*! Called after the viewController is loaded.
 *  This method should never be called directly.
 */
- (void)viewControllerDidLoad;

/*! Called when the module receives a notification.
 *  The module may not be visible or be made active after 
 *  this method is called. Subclasses should call the
 *  super implementation.
 */
- (void)didReceiveNotification:(NSDictionary*)userInfo;

/*! Called when the module receives a URL request.
 *  The module may not be visible or be made active after
 *  this method is called. Subclasses should call the
 *  super implementation.
 */
- (void)didReceiveRequestWithURL:(NSURL*)url;
@end
