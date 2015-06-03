#import "MITActivityTableViewCell.h"

@implementation MITActivityTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    if (self) {

    }

    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {

    }

    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (MITLoadingActivityView*)activityView
{
    if (!_activityView) {
        MITLoadingActivityView *activityView = [[MITLoadingActivityView alloc] init];
        activityView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:activityView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:activityView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.
                                                          constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:activityView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.
                                                          constant:0]];

        _activityView = activityView;
        [self setNeedsLayout];
    }

    return _activityView;
}

@end
