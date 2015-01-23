#import "MITMartyDetailHeaderView.h"

@interface MITMartyDetailHeaderView()

@property (nonatomic,weak) IBOutlet UILabel *titleLabel;
@property (nonatomic,weak) IBOutlet UILabel *statusLabel;

@end

@implementation MITMartyDetailHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self needsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)updateConstraints
{
    self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.titleLabel.frame);
    self.statusLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.statusLabel.frame);
    [super updateConstraints];
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setStatus:(NSString *)status
{
    if ([status isEqualToString:@"Online"]) {
        _statusLabel.textColor = [UIColor colorWithRed:0. green:119/255.0 blue:0. alpha:1];
    } else if ([status isEqualToString:@"Offline"]) {
        _statusLabel.textColor = [UIColor redColor];
    }
    _statusLabel.text = status;
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

@end
