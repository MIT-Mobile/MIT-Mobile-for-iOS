#import <Foundation/Foundation.h>

@class UIViewController;

@protocol MITDiningRefreshableViewController <NSObject>

- (void)refreshRequestComplete;

@end

@protocol MITDiningRefreshRequestDelegate <NSObject>

- (void)viewControllerRequestsDataUpdate:(UIViewController<MITDiningRefreshableViewController> *)viewController;

@end