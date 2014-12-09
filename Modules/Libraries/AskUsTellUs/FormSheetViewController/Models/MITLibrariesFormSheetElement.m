#import "MITLibrariesFormSheetElement.h"
#import "MITLibrariesFormSheetElementAvailableOption.h"

@implementation MITLibrariesFormSheetElement

- (id)htmlParameterValue
{
    id htmlReturnVal = self.value;
    if (self.type == MITLibrariesFormSheetElementTypeOptions) {
        for (MITLibrariesFormSheetElementAvailableOption *availableOption in self.availableOptions) {
            if ([availableOption.value isEqual:self.value]) {
                htmlReturnVal = availableOption.htmlValue;
                break;
            }
        }
    }
    return htmlReturnVal;
}
- (id)value
{
    if (!_value) {
        MITLibrariesFormSheetElementAvailableOption *firstAvailableOption = [self.availableOptions firstObject];
        _value = firstAvailableOption.value;
    }
    return _value;
}
- (NSString *)title
{
    return !_optional ? _title : [NSString stringWithFormat:@"%@ (optional)", _title];
}

- (void)setAvailableOptions:(NSArray *)availableOptions
{
    if (![availableOptions.firstObject isKindOfClass:[MITLibrariesFormSheetElementAvailableOption class]]) {
        NSMutableArray *updatedOptions = [NSMutableArray array];
        for (id option in availableOptions) {
            MITLibrariesFormSheetElementAvailableOption *opt = [MITLibrariesFormSheetElementAvailableOption new];
            opt.value = option;
            [updatedOptions addObject:opt];
        }
        _availableOptions = updatedOptions;
    } else {
        _availableOptions = availableOptions;
    }
}

@end