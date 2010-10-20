
#import "MITLoadingActivityView.h"


@implementation MITLoadingActivityView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		// Initialization code
		
		UIActivityIndicatorView *spinny = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		[spinny startAnimating];
		
		UILabel *loadingLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		NSString *loadingText = @"Loading...";
		loadingLabel.backgroundColor = [UIColor clearColor];
		loadingLabel.text = loadingText;
		CGSize labelSize = [loadingText sizeWithFont:loadingLabel.font];
		loadingLabel.frame = CGRectMake(spinny.frame.size.width + 2.0, 0.0, labelSize.width, labelSize.height);
		
		UIView *centeredView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, labelSize.width + spinny.frame.size.width + 2.0, labelSize.height)] autorelease];
		[centeredView addSubview:spinny];
		[centeredView addSubview:loadingLabel];
		
		centeredView.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
		[self addSubview:centeredView];
		
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	UIImage *image = [UIImage imageNamed:MITImageNameBackground];
	[image drawInRect:rect];
}


- (void)dealloc {
    [super dealloc];
}


@end
