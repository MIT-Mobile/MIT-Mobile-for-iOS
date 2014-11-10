#import "MITLibrariesFormSheetElementPhoneNumber.h"

@implementation MITLibrariesFormSheetElementPhoneNumber
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
        self.title = @"Phone";
        self.htmlParameterKey = @"phone";
        self.optional = YES;
    }
    return self;
}
@end
