
#import "MITLoadingActivityView.h"


@implementation MITLoadingActivityView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.opaque = YES;
    }
    return self;
}

- (void)layoutSubviews {
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageNameBackground]];
        CGRect frame = self.frame;
        frame.origin = CGPointZero;
        
        imageView.frame = frame;
        _backgroundView = imageView;
        [self addSubview:imageView];
    }
    
    {
        CGFloat labelLeftMargin = 5.0;
        CGRect frame = self.frame;
        UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		[spinny startAnimating];
		
		UILabel *loadingLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		NSString *loadingText = @"Loading...";
		loadingLabel.backgroundColor = [UIColor clearColor];
		loadingLabel.text = loadingText;
		CGSize labelSize = [loadingText sizeWithFont:loadingLabel.font];
		loadingLabel.frame = CGRectMake(spinny.frame.size.width + labelLeftMargin, 0.0, labelSize.width, labelSize.height);
		
        CGRect viewFrame = CGRectMake(0.0,
                                      0.0,
                                      labelSize.width + spinny.frame.size.width + labelLeftMargin,
                                      labelSize.height);
		UIView *centeredView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
		[centeredView addSubview:spinny];
		[centeredView addSubview:loadingLabel];
		
		centeredView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
		[self addSubview:centeredView];
    }
}

- (void)dealloc {
    [_backgroundView release], _backgroundView = nil;
    
    [super dealloc];
}


@end
