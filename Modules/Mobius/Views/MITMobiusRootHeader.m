#import "MITMobiusRootHeader.h"

@interface MITMobiusRootHeader()

@end

@implementation MITMobiusRootHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (UINib *)rootHeaderNib
{
    return [UINib nibWithNibName:self.rootHeaderNibName bundle:nil];
}

+ (NSString *)rootHeaderNibName
{
    return @"MITMobiusRootHeader";
}

@end
