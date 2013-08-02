#import <Foundation/Foundation.h>

@class LibraryEmailFormViewController;
@class LibraryFormElement;

@interface LibraryFormElementGroup : NSObject {
@private
    NSArray *formElements;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *headerText;
@property (nonatomic, retain) NSString *footerText;
@property (nonatomic) BOOL hidden;
@property (nonatomic, assign) LibraryEmailFormViewController *formViewController;

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
