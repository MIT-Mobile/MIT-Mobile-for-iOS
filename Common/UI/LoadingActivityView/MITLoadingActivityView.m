#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"

@interface MITLoadingActivityView ()
@property (nonatomic,strong) UIView *contentView;
@property (nonatomic,weak) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic,weak) UILabel *textLabel;
@end

@implementation MITLoadingActivityView {
    BOOL _didSetupViewConstraints;
}

@synthesize usesBackgroundImage = _usesBackgroundImage;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIView *contentView = [[UIView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:contentView];
        _contentView = contentView;

        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        textLabel.text = @"Loading...";
        [contentView addSubview:textLabel];
        _textLabel = textLabel;

        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:activityIndicatorView];
        _activityIndicatorView = activityIndicatorView;

        self.usesBackgroundImage = YES;

        self.backgroundColor = [UIColor redColor];
        //self.contentView.backgroundColor = [UIColor blueColor];
    }

    return self;
}

- (void)updateConstraints
{
    [super updateConstraints];

    if (!_didSetupViewConstraints) {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.
                                                          constant:0]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activityView]-[textLabel]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"activityView" : self.activityIndicatorView,
                                                                               @"textLabel" : self.textLabel}]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[activityView]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"activityView" : self.activityIndicatorView}]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"textLabel" : self.textLabel}]];
        _didSetupViewConstraints = YES;
    }
}

- (void)setUsesBackgroundImage:(BOOL)usesBackgroundImage
{
    if (usesBackgroundImage != self.usesBackgroundImage) {
        _usesBackgroundImage = usesBackgroundImage;


        /*
         if (self.usesBackgroundImage) {
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                self.backgroundColor = [UIColor groupTableViewBackgroundColor];
            } else {
                self.backgroundColor = [UIColor mit_backgroundColor];
            }
        } else {
            self.backgroundColor = [UIColor clearColor];
        }
        [self setNeedsDisplay];
         */
    }
}

@end
