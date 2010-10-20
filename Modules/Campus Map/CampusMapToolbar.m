#import "CampusMapToolbar.h"


@implementation CampusMapToolbar


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	UIImage *image = [[UIImage imageNamed:@"toolbar-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
	[image drawInRect:rect];
}


- (void)dealloc {
    [super dealloc];
}


@end
