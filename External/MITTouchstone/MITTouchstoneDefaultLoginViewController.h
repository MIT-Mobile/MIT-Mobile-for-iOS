#import <UIKit/UIKit.h>

@protocol MITTouchstoneLoginViewControllerDelegate;

@interface MITTouchstoneDefaultLoginViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic,weak) id<MITTouchstoneLoginViewControllerDelegate> delegate;
@property (nonatomic,strong) NSOperationQueue *authenticationOperationQueue;
@property (nonatomic,readonly) NSURLCredential *credential;


- (instancetype)init;
- (instancetype)initWithCredential:(NSURLCredential*)credential;

@end

@protocol MITTouchstoneLoginViewControllerDelegate <NSObject>
- (BOOL)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller canLoginForUser:(NSString*)user;
- (void)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller didFinishWithCredential:(NSURLCredential*)credential;
- (void)didCancelLoginViewController:(MITTouchstoneDefaultLoginViewController*)controller;
@end