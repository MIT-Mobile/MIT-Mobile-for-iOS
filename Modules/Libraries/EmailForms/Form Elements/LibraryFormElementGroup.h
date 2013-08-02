#import <Foundation/Foundation.h>

@class LibraryEmailFormViewController;
@class LibraryFormElement;

@interface LibraryFormElementGroup : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *footerText;
@property BOOL hidden;
@property (nonatomic, weak) LibraryEmailFormViewController *formViewController;

+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements;
+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements;

- (NSInteger)numberOfRows;
- (BOOL)valueRequiredForKey:(NSString *)key;
- (NSArray *)keys;
- (NSArray *)elements;
- (NSString *)keyForRow:(NSInteger)row;
- (LibraryFormElement *)formElementForKey:(NSString *)key;
- (NSArray *)textInputViews;

- (id)initWithName:(NSString *)name formElements:(NSArray *)formElements;


- (NSString *)getFormValueForKey:(NSString *)key;

@end
