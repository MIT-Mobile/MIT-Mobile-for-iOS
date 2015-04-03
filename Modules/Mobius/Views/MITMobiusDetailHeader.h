#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@interface MITMobiusDetailHeader : UIView

@property (nonatomic, copy) MITMobiusResource *resource;

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;

@end
