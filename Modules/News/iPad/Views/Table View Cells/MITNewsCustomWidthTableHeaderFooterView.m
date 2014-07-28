#import "MITNewsCustomWidthTableHeaderFooterView.h"

static NSUInteger maximumWidthOfTable = 648;

@implementation MITNewsCustomWidthTableHeaderFooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    if (frame.size.width > maximumWidthOfTable) {
        frame.origin.x += (frame.size.width - maximumWidthOfTable) / 2;
        frame.size.width = maximumWidthOfTable;
    }
    [super setFrame:frame];
}


@end
