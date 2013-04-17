#import "MGSErrorView.h"

@interface MGSErrorView ()
@property (nonatomic,weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,weak) UIImageView *warningImageView;
@property (nonatomic,weak) UILabel *errorLabel;
@end

@implementation MGSErrorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.hidesWhenStopped = YES;
        [activityIndicator startAnimating];
        self.activityIndicator = activityIndicator;
        [self addSubview:activityIndicator];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.hidden = YES;
        self.warningImageView = imageView;
        [self addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        self.errorLabel = label;
        [self addSubview:label];
    }
    
    return self;
}

- (void)setError:(NSError *)error
{
    _error = error;
    [self setNeedsLayout];
}

- (void)setError:(NSError *)error
        animated:(BOOL)animated
{
    self.error = error;
    [UIView animateWithDuration:(animated ? 0.4 : 0.0)
                     animations:^{
                         [self layoutIfNeeded];
                     }];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
    if (self.error) {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
        
        {
            if (self.warningImageView.image == nil) {
                self.warningImageView.image = [UIImage imageNamed:@"map/map-warning"];
            }
            
            CGFloat imageRatio = self.warningImageView.image.size.height / self.warningImageView.image.size.width;
            CGFloat imageWidth = (CGRectGetWidth(bounds) * 0.65);
            CGFloat imageHeight = (imageWidth * imageRatio);
            CGRect imageFrame = CGRectMake(CGRectGetMidX(bounds) - (imageWidth / 2.0),
                                           CGRectGetMidY(bounds) - (imageHeight / 2.0),
                                           imageWidth,
                                           imageHeight);
            self.warningImageView.frame = imageFrame;
            self.warningImageView.hidden = NO;
        }
    } else {
        self.warningImageView.hidden = YES;
        self.errorLabel.hidden = YES;
        
        CGRect activityRect = self.activityIndicator.frame;
        activityRect.origin = CGPointMake(CGRectGetMidX(bounds) - (CGRectGetWidth(activityRect) / 2.0),
                                          CGRectGetMidY(bounds) - (CGRectGetHeight(activityRect) / 2.0));
        self.activityIndicator.frame = activityRect;
        self.activityIndicator.hidden = NO;
    }
}
@end
