#import "MITMobiusSegmentedHeader.h"

@implementation MITMobiusSegmentedHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (UINib *)segmentedHeaderNib
{
    return [UINib nibWithNibName:self.segmentedHeaderNibName bundle:nil];
}

+ (NSString *)segmentedHeaderNibName
{
    return @"MITMobiusSegmentedHeader";
}
- (IBAction)detailSegmentControlAction:(UISegmentedControl *)segmentedControl
{
    [self.delegate detailSegmentControlAction:segmentedControl];
}

@end
