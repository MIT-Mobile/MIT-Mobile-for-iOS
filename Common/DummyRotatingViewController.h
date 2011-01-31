/* The sole purpose of this UIViewController subclass is to
 * have the return value of -[shouldRotate...] set externally
 */

#import <UIKit/UIKit.h>


@interface DummyRotatingViewController : UIViewController {
    BOOL canRotate;
}

@property BOOL canRotate;

@end
