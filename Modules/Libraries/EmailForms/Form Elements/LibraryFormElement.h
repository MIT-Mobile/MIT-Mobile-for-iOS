#import <Foundation/Foundation.h>

@protocol LibraryFormElementDelegate;
@class LibraryEmailFormViewController;

@interface LibraryFormElement : NSObject
@property (copy) NSString *key;
@property (nonatomic,copy) NSString *displayLabel;
@property (copy) NSString *displayLabelSubtitle;
@property (getter = isRequired) BOOL required;
@property (nonatomic, weak) LibraryEmailFormViewController *formViewController;
@property (nonatomic, weak) id<LibraryFormElementDelegate> delegate;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel displayLabelSubtitle:(NSString *)displayLabelSubtitle required:(BOOL)required;

- (void)updateCell:(UITableViewCell *)tableViewCell;
- (UITableViewCell *)tableViewCell;
- (CGFloat)heightForTableViewCell;
- (UIView *)textInputView;
- (NSString *)value;
@end

@protocol LibraryFormElementDelegate
- (void)valueChangedForElement:(LibraryFormElement *)element;
@end