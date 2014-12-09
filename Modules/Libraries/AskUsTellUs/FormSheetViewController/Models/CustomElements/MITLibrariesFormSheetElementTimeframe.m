#import "MITLibrariesFormSheetElementTimeframe.h"

@implementation MITLibrariesFormSheetElementTimeframe
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
        self.title = @"Timeframe";
        self.htmlParameterKey = @"timeframe";
    }
    return self;
}
@end
