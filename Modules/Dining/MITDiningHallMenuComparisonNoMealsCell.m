#import "MITDiningHallMenuComparisonNoMealsCell.h"

@interface MITDiningHallMenuComparisonNoMealsCell ()

@property (nonatomic, strong) UILabel   * primaryLabel;

@end

@implementation MITDiningHallMenuComparisonNoMealsCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.primaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.primaryLabel.backgroundColor = [UIColor clearColor];
        self.primaryLabel.textAlignment = NSTextAlignmentCenter;
        self.primaryLabel.font = [UIFont systemFontOfSize:10];
        [self addSubview:self.primaryLabel];
    }
    return self;
}

- (void) prepareForReuse
{
    self.primaryLabel.text = @"";
}

@end