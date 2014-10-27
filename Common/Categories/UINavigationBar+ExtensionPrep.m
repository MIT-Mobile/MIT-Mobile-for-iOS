#import "UINavigationBar+ExtensionPrep.h"

@implementation UINavigationBar (ExtensionPrep)

- (void)prepareForExtensionWithBackgroundColor:(UIColor *)backgroundColor
{
    self.translucent = NO;
    
    [self removeShadow];
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
}

- (void)removeShadow
{
    [self setShadowImage:[UIImage imageNamed:MITImageTransparentPixel]];
}

- (void)restoreShadow
{
    [self setShadowImage:nil];
}

@end
