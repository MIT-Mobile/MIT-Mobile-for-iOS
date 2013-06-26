
#import "DiningHallMenuComparisonNoMealsCell.h"

@interface DiningHallMenuComparisonNoMealsCell ()

@property (nonatomic, strong) UILabel   * primaryLabel;

@end

@implementation DiningHallMenuComparisonNoMealsCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.primaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, frame.size.width, frame.size.height)];
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


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
