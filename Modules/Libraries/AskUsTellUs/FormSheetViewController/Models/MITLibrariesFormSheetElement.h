#import <Foundation/Foundation.h>
#import "MITLibrariesFormSheetElementAvailableOption.h"

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
@property (nonatomic, strong) NSArray *availableOptions; // Used for type 'Options' to indicate possible values.  Array<MITLibrariesFormSheetAvailableOption> or Array<id> depending on need.
@property (nonatomic) BOOL optional;
@property (nonatomic, copy) NSString *htmlParameterKey; // The corresponding HTML argument
@property (nonatomic, readonly) id htmlParameterValue; // The current value formatted for its html argument
@end

