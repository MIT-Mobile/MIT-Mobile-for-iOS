#import "MITMapPlaceBottomButtonCell.h"

@interface MITMapPlaceBottomButtonCell()

@property (nonatomic, weak) IBOutlet UIView *topSeparator;

@end

@implementation MITMapPlaceBottomButtonCell

- (void)setTopSeparatorHidden:(BOOL)hidden
{
    self.topSeparator.hidden = hidden;
}

@end
