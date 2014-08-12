//
//  DiningHallInfoGeneralCell.m
//  MIT Mobile
//
//  Created by Logan Wright on 8/12/14.
//
//

#import "MITDiningHallInfoGeneralCell.h"

static CGFloat const kLeftOffset = 15.0;

@interface MITDiningHallInfoGeneralCell ()

@property (strong, nonatomic) CALayer *cellSeparator;

@end

@implementation MITDiningHallInfoGeneralCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

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
    self.cellSeparator.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.layer addSublayer:self.cellSeparator];
}

- (void)positionCellSeparator
{
    self.cellSeparator.frame = CGRectMake(kLeftOffset, CGRectGetMaxY(self.bounds), CGRectGetWidth(self.bounds) - kLeftOffset, -0.5);
}

@end
