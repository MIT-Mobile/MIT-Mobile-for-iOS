#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface DiningHallDetailHeaderView ()

@property (nonatomic, retain) UIImageView   * iconView;
@property (nonatomic, retain) UILabel       * titleLabel;
@property (nonatomic, retain) UILabel       * timeLabel;
@property (nonatomic, retain) UIButton      * infoButton;
@property (nonatomic, retain) UIButton      * starButton;

@end


@implementation DiningHallDetailHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor colorWithHexString:@"#e1e3e8"];
        
        // dimensions derived from https://jira.mit.edu/jira/secure/attachment/26097/house+menu.pdf
        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 44, 44)];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 10, frame.size.width - 124, 44)];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 64, frame.size.width - 50, 16)];
        
        self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        CGSize size = self.infoButton.frame.size;
        self.infoButton.frame = CGRectIntegral(CGRectMake(frame.size.width - ((50 + size.width) / 2.0),
                                                          (67. - size.height) / 2.0,
                                                          size.width,
                                                          size.height));
        self.infoButton.hidden = YES;

        self.starButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self.starButton setImage:[UIImage imageNamed:@"dining/bookmark"] forState:UIControlStateNormal];
        [self.starButton setImage:[UIImage imageNamed:@"dining/bookmark_selected"] forState:UIControlStateSelected];

        size = self.starButton.frame.size;
        self.starButton.frame = CGRectMake(frame.size.width - 50, 0, 50, 67);

        self.starButton.hidden = YES;
        
        [self styleSubviews];
        
        [self addSubview:self.iconView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.timeLabel]; 
        [self addSubview:self.infoButton];
        [self addSubview:self.starButton];
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
}

@end
