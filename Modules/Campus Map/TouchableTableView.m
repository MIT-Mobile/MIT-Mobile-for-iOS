
#import "TouchableTableView.h"


@implementation TouchableTableView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
    [super dealloc];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	
	if([self.delegate respondsToSelector:@selector(touchEnded)])
	{
		[self.delegate performSelector:@selector(touchEnded)];
	}
}

@end
