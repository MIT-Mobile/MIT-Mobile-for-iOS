#import <Foundation/Foundation.h>

typedef void (^MITActionSheetDelegateBlock)(UIActionSheet *actionSheet, NSInteger buttonIndex);

@interface MITActionSheetHandler : NSObject <UIActionSheetDelegate>

@property (nonatomic, strong) MITActionSheetDelegateBlock delegateBlock;
@property (nonatomic, strong) UIColor *actionSheetTintColor;

@end
