
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITLibrariesFormSheetElementType) {
    MITLibrariesFormSheetElementTypeOptions,
    MITLibrariesFormSheetElementTypeSingleLineTextEntry,
    MITLibrariesFormSheetElementTypeMultiLineTextEntry,
    MITLibrariesFormSheetElementTypeWebLink
};

@interface MITLibrariesFormSheetElement : NSObject
@property (nonatomic) MITLibrariesFormSheetElementType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) id value;
@property (nonatomic) BOOL optional;
@property (nonatomic, copy) NSString *htmlParameterKey; // The corresponding HTML argument
@property (nonatomic, strong) id htmlParamaterValue; // If different from `value`.  If this is nil, it will return the contents of 'value'.
@end

