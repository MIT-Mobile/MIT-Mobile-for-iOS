
#import "MITLibrariesFormSheetElement.h"
#import "MITLibrariesFormSheetElementAvailableOption.h"

@implementation MITLibrariesFormSheetElement
- (id)htmlParamaterValue
{
    id htmlReturnVal = _value;
    if ([htmlReturnVal isKindOfClass:[MITLibrariesFormSheetElementAvailableOption class]]) {
        htmlReturnVal = [(MITLibrariesFormSheetElementAvailableOption *)htmlReturnVal htmlValue];
    }
    return htmlReturnVal;
}
- (id)value
{
    if (!_value) {
        id firstAvailableOption = [self.availableOptions firstObject];
        if ([firstAvailableOption isKindOfClass:[MITLibrariesFormSheetElementAvailableOption class]]) {
            firstAvailableOption = [(MITLibrariesFormSheetElementAvailableOption *)firstAvailableOption value];
        }
        _value = firstAvailableOption;
    }
    
    id returnVal = _value;
    if ([returnVal isKindOfClass:[MITLibrariesFormSheetElementAvailableOption class]]) {
        returnVal = [(MITLibrariesFormSheetElementAvailableOption *)returnVal value];
    }
    return returnVal;
}
- (NSString *)title
{
    return !_optional ? _title : [NSString stringWithFormat:@"%@ (optional)", _title];
}
@end