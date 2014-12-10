#import "MITLibrariesFormSheetElementDepartment.h"

@implementation MITLibrariesFormSheetElementDepartment
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeSingleLineTextEntry;
        self.title = @"Department, Lab, or Center";
        self.htmlParameterKey = @"department";
    }
    return self;
}
@end
