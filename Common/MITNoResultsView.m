#import "MITNoResultsView.h"
#import "UIKit+MITAdditions.h"

@interface MITNoResultsView ()
@property (nonatomic,retain) UIView *activityView;
@end

@implementation MITNoResultsView

@synthesize usesBackgroundImage = _usesBackgroundImage;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.usesBackgroundImage = YES;
        
        UIView *activityView = [[UIView alloc] init];
        UILabel *loadingLabel = [[UILabel alloc] init];
        
        NSString *loadingText = @"No Results";
        
        CGSize labelSize = [loadingText sizeWithFont:loadingLabel.font];
        CGFloat labelLeftMargin = 6.0;
        loadingLabel.frame = CGRectMake(labelLeftMargin,
                                        0.0,
                                        labelSize.width,
                                        labelSize.height);
        loadingLabel.backgroundColor = [UIColor clearColor];
        loadingLabel.text = loadingText;
        
        CGRect viewFrame = CGRectMake(0.0,
                                      0.0,
                                      labelSize.width + labelLeftMargin,
                                      labelSize.height);
        
        activityView.frame = viewFrame;
        activityView.autoresizingMask = UIViewAutoresizingNone;
        
        [activityView addSubview:loadingLabel];
        
        [self addSubview:activityView];
        self.activityView = activityView;
    }
    return self;
}

- (void)layoutSubviews {
    // center the loading indicator
    CGRect frame = self.activityView.frame;
    frame.origin.x = (self.bounds.size.width - frame.size.width) / 2.0;
    frame.origin.y = (self.bounds.size.height - frame.size.height - 64.) / 2.0;
    // make sure it is always whole pixel aligned
    self.activityView.frame = CGRectIntegral(frame);
}

- (void)dealloc {
    self.activityView = nil;
    
}

- (void)setUsesBackgroundImage:(BOOL)usesBackgroundImage
{
    if (usesBackgroundImage != self.usesBackgroundImage) {
        _usesBackgroundImage = usesBackgroundImage;
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
    }
}

@end
