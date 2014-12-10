#import "MITLibrariesFormSheetElementHowCanWeHelp.h"

@implementation MITLibrariesFormSheetElementHowCanWeHelp
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
        self.title = @"How can we help you?";
        self.htmlParameterKey = @"description";
    }
    return self;
}
@end
