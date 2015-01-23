#import <UIKit/UIKit.h>

@interface UINavigationBar (ExtensionPrep)

- (void)prepareForExtensionWithBackgroundColor:(UIColor *)backgroundColor;
- (void)removeShadow;
- (void)restoreShadow;

@end
