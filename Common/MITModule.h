#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MITModuleItem;

@interface MITModule : NSObject
@property(nonatomic,readonly,copy) NSString *name;
@property(nonatomic,readonly,copy) NSString *title;
@property(nonatomic,copy) NSString *longTitle;

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,copy) NSString *imageName;

@property(nonatomic,strong) IBOutlet UIViewController *viewController;

- (instancetype)initWithName:(NSString*)name title:(NSString*)title;

- (BOOL)supportsCurrentUserInterfaceIdiom;
- (BOOL)isViewControllerLoaded;

/*! Called when the module's view controller needs to be loaded.
 *  The subclass must create and assign a view controller to the 
 *  viewController property before returning from this method. By default,
 *  a UIViewController with an empty UIView will be created if the
 *  method is not overridded.
 */
- (void)loadViewController;
- (void)viewControllerDidLoad;

- (void)didReceiveNotification:(NSDictionary*)userInfo;
- (void)didReceiveRequestWithURL:(NSURL*)url;
@end
