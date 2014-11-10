#import "MITLibrariesFormSheetElementConsultationSubject.h"

@implementation MITLibrariesFormSheetElementConsultationSubject
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeOptions;
        self.title = @"Subject";
        self.htmlParameterKey = @"subject";
        self.availableOptions = @[@"General", @"Art & Architecture", @"Engineering & Computer Science", @"GIS", @"Humanities", @"Management & Business", @"Science", @"Social Sciences", @"Urban Planning"];
    }
    return self;
}
@end
