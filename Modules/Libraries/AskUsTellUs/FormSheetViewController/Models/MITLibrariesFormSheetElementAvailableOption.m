#import "MITLibrariesFormSheetElementAvailableOption.h"

@implementation MITLibrariesFormSheetElementAvailableOption
- (id)htmlValue
{
    if (!_htmlValue && _value) {
        return _value;
    }
    return _htmlValue;
}
@end
