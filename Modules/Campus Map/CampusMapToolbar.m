#import "CampusMapToolbar.h"


@implementation CampusMapToolbar


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	UIImage *image = [[UIImage imageNamed:@"global/toolbar-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
	[image drawInRect:rect];
}


- (void)dealloc {
    [super dealloc];
}


@end
