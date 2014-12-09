#import "MITLibrariesFormSheetElementCourse.h"

@implementation MITLibrariesFormSheetElementCourse
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
        self.title = @"Course";
        self.htmlParameterKey = @"course";
    }
    return self;
}
@end
