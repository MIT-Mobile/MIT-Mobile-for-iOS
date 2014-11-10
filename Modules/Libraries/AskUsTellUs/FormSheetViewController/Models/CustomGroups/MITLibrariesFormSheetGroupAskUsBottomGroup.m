#import "MITLibrariesFormSheetGroupAskUsBottomGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupAskUsBottomGroup
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        MITLibrariesFormSheetElementStatus *status = [MITLibrariesFormSheetElementStatus new];
        MITLibrariesFormSheetElement *department = [MITLibrariesFormSheetElementDepartment new];
        MITLibrariesFormSheetElement *phoneNumber = [MITLibrariesFormSheetElementPhoneNumber new];
        
        self.headerTitle = @"PERSONAL INFO";
        self.footerTitle = nil;
        self.elements = @[status, department, phoneNumber];
    }
    return self;
}
@end
