#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MITDrawerItem;
@class MITNotification;

@interface UIViewController (MITDrawerNavigation)
@property (nonatomic,readwrite,strong) MITDrawerItem *drawerItem;

// returns YES if the module can handle the incoming notification
// defaults to NO
- (BOOL)mit_canHandleNotification:(MITNotification*)notification;

// Return YES if the view controller should be made visible after processing the notification
// defaults to NO
- (BOOL)mit_handleNotification:(MITNotification*)notification;

// returns YES if the module can handle the incoming URL
// defaults to NO
- (BOOL)mit_canHandleURL:(NSURL*)url;

// Return YES if the view controller should be made visible after processing the URL
// defaults to NO
- (BOOL)mit_handleURL:(NSURL*)url;
@end

@interface MITDrawerItem : UIBarItem
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *longTitle;
@property (nonatomic,strong) UIImage *selectedImage;

- (instancetype)initWithTitle:(NSString*)title image:(UIImage*)image;
- (instancetype)initWithTitle:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage;
@end
