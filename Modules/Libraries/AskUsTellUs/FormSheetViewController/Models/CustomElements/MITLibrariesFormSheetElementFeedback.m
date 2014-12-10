#import "MITLibrariesFormSheetElementFeedback.h"

@implementation MITLibrariesFormSheetElementFeedback
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
        self.title = @"Feedback";
        self.htmlParameterKey = @"feedback";
    }
    return self;
}
@end
