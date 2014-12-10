#import "MITLibrariesFormSheetGroupTechnicalHelp.h"
#import "MITLibrariesFormSheetElement.h"

@implementation MITLibrariesFormSheetGroupTechnicalHelp
- (instancetype)init
{
    self = [super init];
    if (self) {
        MITLibrariesFormSheetElement *usingVPN = [MITLibrariesFormSheetElement new];
        usingVPN.type = MITLibrariesFormSheetElementTypeOptions;
        usingVPN.title = @"Using VPN";
        usingVPN.htmlParameterKey = @"vpn";
        MITLibrariesFormSheetElementAvailableOption *no = [MITLibrariesFormSheetElementAvailableOption new];
        no.value = @"No";
        no.htmlValue = @"no";
        MITLibrariesFormSheetElementAvailableOption *yes = [MITLibrariesFormSheetElementAvailableOption new];
        yes.value = @"Yes";
        yes.htmlValue = @"yes";
        usingVPN.availableOptions = @[no, yes];
        
        MITLibrariesFormSheetElement *location = [MITLibrariesFormSheetElement new];
        location.type = MITLibrariesFormSheetElementTypeOptions;
        location.title = @"Location";
        location.htmlParameterKey = @"on_campus";
        MITLibrariesFormSheetElementAvailableOption *onCampus = [MITLibrariesFormSheetElementAvailableOption new];
        onCampus.value = @"On Campus";
        onCampus.htmlValue = @"on campus";
        MITLibrariesFormSheetElementAvailableOption *offCampus = [MITLibrariesFormSheetElementAvailableOption new];
        offCampus.value = @"Off Campus";
        offCampus.htmlValue = @"off campus";
        location.availableOptions = @[onCampus, offCampus];
        
        self.headerTitle = @"TECHNICAL HELP";
        self.elements = @[usingVPN, location];
    }
    return self;
}
@end
