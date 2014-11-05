
#import "MITLibrariesFormSheetElement.h"

@implementation MITLibrariesFormSheetElement
- (id)htmlParamaterValue
{
    if (!_htmlParamaterValue) {
        return _value;
    } else {
        return _htmlParamaterValue;
    }
}
@end