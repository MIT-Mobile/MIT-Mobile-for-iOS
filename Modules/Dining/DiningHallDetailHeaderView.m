#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface DiningHallDetailHeaderView ()

@property (nonatomic, retain) UIImageView   * icon;
@property (nonatomic, retain) UILabel       * titleLabel;
@property (nonatomic, retain) UILabel       * timeLabel;
@property (nonatomic, retain) UIButton      * accessoryButton;

@end


@implementation DiningHallDetailHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // dimensions derived from https://jira.mit.edu/jira/secure/attachment/26097/house+menu.pdf
        self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 44, 44)];
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 10, frame.size.width - 124, 44)];
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 64, frame.size.width - 60, 13)];
        self.accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.accessoryButton.frame = CGRectMake(frame.size.width - 60, 0, 60, frame.size.height);

        [self styleSubviews];
        [self debugInfo];
        
        [self addSubview:self.icon];
        [self addSubview:self.titleLabel];
        [self addSubview:self.timeLabel];
        [self addSubview:self.accessoryButton];
    }
    return self;
}

- (void) styleSubviews
{
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.shadowColor = [UIColor whiteColor];
    self.titleLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    self.timeLabel.shadowColor = [UIColor whiteColor];
    self.timeLabel.shadowOffset = CGSizeMake(0, 1);
    
    self.accessoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
}

- (void) debugInfo
{
    self.backgroundColor = [UIColor colorWithHexString:@"#d4d6db"];
    
    self.titleLabel.text = @"Some Dining Hall";
    self.timeLabel.text = @"Opens never";
    self.icon.image = [UIImage imageNamed:@"icons/home-map.png"];
}

@end
