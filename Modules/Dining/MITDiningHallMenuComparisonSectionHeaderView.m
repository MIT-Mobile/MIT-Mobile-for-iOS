#import "MITDiningHallMenuComparisonSectionHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface MITDiningHallMenuComparisonSectionHeaderView ()

@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UILabel * timeLabel;

@end

@implementation MITDiningHallMenuComparisonSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat halfHeight = CGRectGetHeight(frame) * 0.5f;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), halfHeight)];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.titleLabel.backgroundColor = [UIColor colorWithHexString:@"#e1e3e8"];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(frame), halfHeight)];
        self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.timeLabel.backgroundColor = [UIColor colorWithHexString:@"#333333"];
        self.timeLabel.font = [UIFont boldSystemFontOfSize:12];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        self.timeLabel.textColor = [UIColor whiteColor];
        
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.timeLabel];
    }
    return self;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.timeLabel.text = nil;
}

@end
