#import "MITLibrariesFormSheetElementPurpose.h"

@implementation MITLibrariesFormSheetElementPurpose
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeOptions;
        self.title = @"Purpose";
        self.htmlParameterKey = @"purpose";
        self.availableOptions = @[@"Course", @"Thesis", @"Research"];
    }
    return self;
}
@end
