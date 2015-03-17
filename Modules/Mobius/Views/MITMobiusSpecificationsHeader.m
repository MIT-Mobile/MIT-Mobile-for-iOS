#import "MITMobiusSpecificationsHeader.h"

@interface MITMobiusSpecificationsHeader ()

@end

@implementation MITMobiusSpecificationsHeader
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

+ (UINib *)titleHeaderNib
{
    return [UINib nibWithNibName:self.titleHeaderNibName bundle:nil];
}

+ (NSString *)titleHeaderNibName
{
    return @"MITMobiusSpecificationsHeader";
}

@end
