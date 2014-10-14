#import "MITDiningCustomSeparatorCell.h"
#import "UIKit+MITAdditions.h"

static CGFloat const kLeftOffset = 15.0;

@interface MITDiningCustomSeparatorCell ()

@property (strong, nonatomic) CALayer *cellSeparator;

@end

@implementation MITDiningCustomSeparatorCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self positionCellSeparator];
}

#pragma mark - Cell Separator

- (void)setShouldIncludeSeparator:(BOOL)shouldIncludeSeparator
{
    _shouldIncludeSeparator = shouldIncludeSeparator;
    if (shouldIncludeSeparator) {
        [self drawCellSeparator];
        [self positionCellSeparator];
    } else {
        [self.cellSeparator removeFromSuperlayer];
        self.cellSeparator = nil;
    }
}

- (void)drawCellSeparator
{
    self.cellSeparator = [CALayer layer];
    self.cellSeparator.backgroundColor = [UIColor mit_cellSeparatorColor].CGColor;
    [self.layer addSublayer:self.cellSeparator];
}

- (void)positionCellSeparator
{
    self.cellSeparator.frame = CGRectMake(kLeftOffset, CGRectGetMaxY(self.bounds), CGRectGetWidth(self.bounds) - kLeftOffset, -1);
}

@end