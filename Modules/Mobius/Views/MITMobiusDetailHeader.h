#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@protocol MITMobiusDetailDelegate;

@interface MITMobiusDetailHeader : UIView

@property(nonatomic,weak) id<MITMobiusDetailDelegate> delegate;
@property (nonatomic, copy) MITMobiusResource *resource;

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;

@end

@protocol MITMobiusDetailDelegate <NSObject>

@required
- (IBAction)detailSegmentControlAction:(UISegmentedControl *)segmentedControl;

@end