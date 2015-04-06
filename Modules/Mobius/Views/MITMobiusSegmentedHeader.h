#import <UIKit/UIKit.h>

@protocol MITMobiusSegmentedHeaderDelegate;

@interface MITMobiusSegmentedHeader : UITableViewHeaderFooterView

@property(nonatomic,weak) id<MITMobiusSegmentedHeaderDelegate> delegate;

+ (UINib *)segmentedHeaderNib;
+ (NSString *)segmentedHeaderNibName;

@end

@protocol MITMobiusSegmentedHeaderDelegate <NSObject>

@required
- (IBAction)detailSegmentControlAction:(UISegmentedControl *)segmentedControl;

@end