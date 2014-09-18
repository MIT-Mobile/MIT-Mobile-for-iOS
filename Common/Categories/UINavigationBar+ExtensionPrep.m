#import "UINavigationBar+ExtensionPrep.h"

@implementation UINavigationBar (ExtensionPrep)

- (void)prepareForExtension
{
    self.translucent = NO;
    
    [self setShadowImage:[UIImage imageNamed:@"global/TransparentPixel"]];
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
}

@end
