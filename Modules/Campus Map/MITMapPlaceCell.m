#import "MITMapPlaceCell.h"
#import "MITMapPlace.h"

const CGFloat kMapPlaceCellEstimatedHeight = 44.0;

@interface MITMapPlaceCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation MITMapPlaceCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.frame.size.width;
    self.subtitleLabel.preferredMaxLayoutWidth = self.subtitleLabel.frame.size.width;
}

#pragma mark - Place

- (void)setPlace:(MITMapPlace *)place
{
    self.titleLabel.text = place.title;
    self.subtitleLabel.text = place.subtitle;
}

- (void)setPlace:(MITMapPlace *)place order:(NSInteger)order
{
    self.titleLabel.text = [NSString stringWithFormat:@"%d. %@", order, place.title];
    self.subtitleLabel.text = place.subtitle;
}

@end
