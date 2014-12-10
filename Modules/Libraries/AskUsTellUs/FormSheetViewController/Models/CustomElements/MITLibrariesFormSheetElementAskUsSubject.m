#import "MITLibrariesFormSheetElementAskUsSubject.h"

@implementation MITLibrariesFormSheetElementAskUsSubject
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
        self.title = @"Subject";
        self.htmlParameterKey = @"subject";
    }
    return self;
}
@end
