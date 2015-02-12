#import "MITCalloutDefaultContentView.h"

static CGFloat const kMITCalloutViewInterLabelMargin = 10.0;
static CGFloat const kMITCalloutViewLabelToAccessorySpacing = 8.0;

@interface MITCalloutViewDefaultContentView ()
@property (weak, nonatomic) NSLayoutConstraint *accessoryViewWidthConstraint;
@property (weak, nonatomic) NSLayoutConstraint *accessoryViewRightConstraint;
@property (weak, nonatomic) NSLayoutConstraint *titleLabelHeightConstraint;
@end

@implementation MITCalloutViewDefaultContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Dependent constraints, labels must be setup AFTER accessoryView
        [self setupAccessoryView];
        [self setupTitleLabel];
        [self setupSubtitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [self removeConstraint:self.titleLabelHeightConstraint];
    NSLayoutConstraint *newHeightConstraint;
    if (self.subtitleLabel.text.length == 0) {
        newHeightConstraint = [self titleLabelHeightConstraintWithMultiplier:1.0];
    } else {
        newHeightConstraint = [self titleLabelHeightConstraintWithMultiplier:0.5];
    }
    [self addConstraint:newHeightConstraint];
    self.titleLabelHeightConstraint = newHeightConstraint;
    [super layoutSubviews];
}

- (void)setupAccessoryView {
    [self addSubview:self.accessoryView];
    
    NSLayoutConstraint *verticalCenter, *height, *width, *right;
    verticalCenter = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                                  attribute:NSLayoutAttributeCenterY
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self
                                                  attribute:NSLayoutAttributeCenterY
                                                 multiplier:1.0
                                                   constant:0];
    height = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:nil
                                          attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1.0
                                           constant:15];
    width = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0
                                          constant:15];
    right = [NSLayoutConstraint constraintWithItem:self.accessoryView
                                         attribute:NSLayoutAttributeRight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self
                                         attribute:NSLayoutAttributeRight
                                        multiplier:1.0
                                          constant:0];
    [self addConstraints:@[verticalCenter, height, width, right]];
    
    self.accessoryViewWidthConstraint = width;
    self.accessoryViewRightConstraint = right;
}

- (void)setupTitleLabel {
    [self addSubview:self.titleLabel];
    
    NSLayoutConstraint *top, *left, *right, *height;
    top = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                       attribute:NSLayoutAttributeTop
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:self
                                       attribute:NSLayoutAttributeTop
                                      multiplier:1.0
                                        constant:0];
    left = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                        attribute:NSLayoutAttributeLeft
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                        attribute:NSLayoutAttributeLeft
                                       multiplier:1.0
                                         constant:0];
    right = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                         attribute:NSLayoutAttributeRight
                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                            toItem:self.accessoryView
                                         attribute:NSLayoutAttributeLeft
                                        multiplier:1.0
                                          constant:-kMITCalloutViewLabelToAccessorySpacing];
    height = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                          attribute:NSLayoutAttributeHeight
                                         multiplier:0.5
                                           constant:0];
    [self addConstraints:@[top, left, right, height]];
    self.titleLabelHeightConstraint = height;
}

- (NSLayoutConstraint *)titleLabelHeightConstraintWithMultiplier:(CGFloat)multiplier {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeHeight
                                                                 multiplier:multiplier
                                                                   constant:0];
    return constraint;
}

- (void)setupSubtitleLabel {
    [self addSubview:self.subtitleLabel];
    
    NSLayoutConstraint *height, *left, *right, *bottom;
    height = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                          attribute:NSLayoutAttributeHeight
                                         multiplier:0.5
                                           constant:0];
    left = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                        attribute:NSLayoutAttributeLeft
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                        attribute:NSLayoutAttributeLeft
                                       multiplier:1.0
                                         constant:0];
    right = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                         attribute:NSLayoutAttributeRight
                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                            toItem:self.accessoryView
                                         attribute:NSLayoutAttributeLeft
                                        multiplier:1.0
                                          constant:-5];
    bottom = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                          attribute:NSLayoutAttributeBottom
                                          relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                          attribute:NSLayoutAttributeBottom
                                         multiplier:1.0
                                           constant:0];
    [self addConstraints:@[height, left, right, bottom]];
}

#pragma mark - Getters

- (UIImageView *)accessoryView {
    if (!_accessoryView) {
        _accessoryView = [UIImageView new];
        [_accessoryView setImage:[UIImage imageNamed:@"disclosure-indicator"]];
        _accessoryView.contentMode = UIViewContentModeScaleAspectFit;
        _accessoryView.clipsToBounds = YES;
        _accessoryView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _accessoryView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:17.0];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [UILabel new];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:13.0];
    }
    return _subtitleLabel;
}

#pragma mark - Sizing

- (CGSize)sizeThatFits:(CGSize)size {
    
    CGSize titleLabelSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    CGSize subtitleLabelSize = [self.subtitleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    
    CGFloat width = titleLabelSize.width > subtitleLabelSize.width ? titleLabelSize.width : subtitleLabelSize.width;
    CGFloat height = titleLabelSize.height + subtitleLabelSize.height + kMITCalloutViewInterLabelMargin;
    
    width += kMITCalloutViewLabelToAccessorySpacing + self.accessoryViewWidthConstraint.constant + self.accessoryViewRightConstraint.constant;
    
    return CGSizeMake(width, height);
}

@end

