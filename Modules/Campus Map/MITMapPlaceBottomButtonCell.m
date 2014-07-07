#import "MITMapPlaceBottomButtonCell.h"

@interface MITMapPlaceBottomButtonCell()

@property (nonatomic, weak) IBOutlet UIView *topSeparator;
@property (nonatomic, weak) IBOutlet UIView *bottomSeparator;

@end

@implementation MITMapPlaceBottomButtonCell

- (void)setTopSeparatorHidden:(BOOL)hidden
{
    self.topSeparator.hidden = hidden;
}

- (void)setBottomSeparatorHidden:(BOOL)hidden
{
    self.bottomSeparator.hidden = hidden;
}

@end
