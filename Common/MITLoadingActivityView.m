
#import "MITLoadingActivityView.h"

@interface MITLoadingActivityView ()
@property (nonatomic,retain) UIImageView *backgroundImage;
@property (nonatomic,retain) UIView *activityView;
@end

@implementation MITLoadingActivityView

@synthesize backgroundImage = _backgroundImage,
            activityView = _activityView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self layoutSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    {
        if (self.backgroundImage == nil) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageNameBackground]];
            [self addSubview:imageView];
            self.backgroundImage = imageView;
        }

        self.backgroundImage.frame = self.bounds;
    }
    
    {
        if (self.activityView == nil) {
            UIView *activityView = [[[UIView alloc] init] autorelease];
            UILabel *loadingLabel = [[[UILabel alloc] init] autorelease];
            UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
            
            NSString *loadingText = @"Loading...";
            
            CGSize labelSize = [loadingText sizeWithFont:loadingLabel.font];
            CGFloat labelLeftMargin = 5.0;
            loadingLabel.frame = CGRectMake(spinner.frame.size.width + labelLeftMargin,
                                            0.0,
                                            labelSize.width,
                                            labelSize.height);
            loadingLabel.backgroundColor = [UIColor clearColor];
            loadingLabel.text = loadingText;
            
            CGRect viewFrame = CGRectMake(0.0,
                                          0.0,
                                          labelSize.width + spinner.frame.size.width + labelLeftMargin,
                                          labelSize.height);
            activityView.frame = viewFrame;
            
            [activityView addSubview:spinner];
            [activityView addSubview:loadingLabel];
            
            [spinner startAnimating];
            [self addSubview:activityView];
            self.activityView = activityView;
        }
        
        self.activityView.autoresizingMask = UIViewAutoresizingNone;
		self.activityView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.0,
                                               CGRectGetHeight(self.bounds) / 2.0);
    }
}

- (void)dealloc {
    self.backgroundImage = nil;
    self.activityView = nil;
    
    [super dealloc];
}


@end
