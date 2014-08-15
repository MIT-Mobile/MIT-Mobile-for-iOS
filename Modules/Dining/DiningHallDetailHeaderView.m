#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface DiningHallDetailHeaderView ()

@property (nonatomic, retain) UIImageView   * iconView;
@property (nonatomic, retain) UILabel       * titleLabel;
@property (nonatomic, retain) UILabel       * timeLabel;
@property (nonatomic, retain) UIButton      * infoButton;
@property (nonatomic, retain) UIButton      * starButton;

@property (strong, nonatomic) CALayer *separatorLayer;

@end


@implementation DiningHallDetailHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.shouldIncludeSeparator = YES;
        
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 34, 34)];
        self.iconView.contentMode = UIViewContentModeScaleAspectFill;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 15, frame.size.width - 124, 34)];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 64, frame.size.width - 50, 16)];
        
        self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        CGSize size = self.infoButton.frame.size;
        self.infoButton.frame = CGRectIntegral(CGRectMake(frame.size.width - ((50 + size.width) / 2.0),
                                                          (67. - size.height) / 2.0,
                                                          size.width,
                                                          size.height));
        self.infoButton.hidden = YES;
        
        [self styleSubviews];
        
        [self addSubview:self.iconView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.timeLabel]; 
        [self addSubview:self.infoButton];
        
    }
    return self;
}

- (void) styleSubviews
{
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont systemFontOfSize:13];

    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.titleLabel.shadowColor = [UIColor whiteColor];
        self.titleLabel.shadowOffset = CGSizeMake(0, 1);
        self.timeLabel.shadowColor = [UIColor whiteColor];
        self.timeLabel.shadowOffset = CGSizeMake(0, 1);
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self positionSeparatorLayer];
}

- (void)positionSeparatorLayer
{
    self.separatorLayer.frame = CGRectMake(15, CGRectGetMaxY(self.bounds), CGRectGetWidth(self.bounds) - 15, -0.5);
}

#pragma mark - Separator

- (void)setShouldIncludeSeparator:(BOOL)shouldIncludeSeparator
{
    if (shouldIncludeSeparator) {
        self.separatorLayer = [CALayer layer];
        self.separatorLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
        [self.layer addSublayer:self.separatorLayer];
        [self positionSeparatorLayer];
    } else {
        [self.separatorLayer removeFromSuperlayer];
        self.separatorLayer = nil;
    }
    _shouldIncludeSeparator = shouldIncludeSeparator;
}

@end
