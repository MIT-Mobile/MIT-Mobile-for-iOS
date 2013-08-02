#import "LibraryFormElement.h"

@interface MenuLibraryFormElement : LibraryFormElement
@property (nonatomic) NSInteger currentOptionIndex;
@property (copy) NSArray *options;
@property (copy) NSArray *displayOptions;
@property (copy) NSString *value;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values displayValues:(NSArray *)displayValues;
@end
