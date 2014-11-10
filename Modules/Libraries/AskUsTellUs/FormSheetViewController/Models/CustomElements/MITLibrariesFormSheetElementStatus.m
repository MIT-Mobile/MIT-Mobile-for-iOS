#import "MITLibrariesFormSheetElementStatus.h"
#import "MITLibrariesFormSheetElementAvailableOption.h"

@implementation MITLibrariesFormSheetElementStatus

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeOptions;
        self.title = @"Status";
        self.htmlParameterKey = @"status";
        [self setupAvailableOptions];
    }
    return self;
}

- (void)setupAvailableOptions
{
    MITLibrariesFormSheetElementAvailableOption *undergradStudent = [MITLibrariesFormSheetElementAvailableOption new];
    undergradStudent.value = @"MIT Undergrad Student";
    undergradStudent.htmlValue = @"UG";
    
    MITLibrariesFormSheetElementAvailableOption *gradStudent = [MITLibrariesFormSheetElementAvailableOption new];
    gradStudent.value = @"MIT Grad Student";
    gradStudent.htmlValue = @"GRAD";
    
    MITLibrariesFormSheetElementAvailableOption *faculty = [MITLibrariesFormSheetElementAvailableOption new];
    faculty.value = @"MIT Faculty";
    faculty.htmlValue = @"FAC";
    
    MITLibrariesFormSheetElementAvailableOption *researchStaff = [MITLibrariesFormSheetElementAvailableOption new];
    researchStaff.value = @"MIT Research Staff";
    researchStaff.htmlValue = @"RS";
    
    MITLibrariesFormSheetElementAvailableOption *staff = [MITLibrariesFormSheetElementAvailableOption new];
    staff.value = @"MIT Staff";
    staff.htmlValue = @"STAFF";
    
    MITLibrariesFormSheetElementAvailableOption *visitor = [MITLibrariesFormSheetElementAvailableOption new];
    visitor.value = @"MIT Visitor";
    visitor.htmlValue = @"VS";
    
    self.availableOptions = @[undergradStudent, gradStudent, faculty, researchStaff, staff, visitor];
}

@end
