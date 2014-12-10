#import "MITLibrariesFormSheetElementDetailedQuestion.h"

@implementation MITLibrariesFormSheetElementDetailedQuestion
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeMultiLineTextEntry;
        self.title = @"Detailed question";
        self.htmlParameterKey = @"question";
    }
    return self;
}
@end
