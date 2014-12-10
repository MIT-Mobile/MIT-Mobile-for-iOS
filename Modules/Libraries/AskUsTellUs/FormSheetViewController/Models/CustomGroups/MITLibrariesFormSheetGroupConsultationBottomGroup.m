#import "MITLibrariesFormSheetGroupConsultationBottomGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupConsultationBottomGroup
- (instancetype)init
{
    self = [super init];
    if (self) {
        MITLibrariesFormSheetElementStatus *status = [MITLibrariesFormSheetElementStatus new];
        MITLibrariesFormSheetElement *department = [MITLibrariesFormSheetElementDepartment new];
        MITLibrariesFormSheetElement *phoneNumber = [MITLibrariesFormSheetElementPhoneNumber new];
    
        self.headerTitle = @"PERSONAL INFO";
        self.elements = @[status, department, phoneNumber];
    }
    return self;
}
@end
