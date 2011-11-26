#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITLoadingActivityView.h"
#import "PlaceholderTextView.h"

@class LibraryEmailFormViewController;

@class LibraryFormElement;
@protocol LibraryFormElementDelegate

- (void)valueChangedForElement:(LibraryFormElement *)element;

@end

@interface LibraryFormElement : NSObject {
@private
}

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *displayLabel;
@property (nonatomic, retain) NSString *displayLabelSubtitle;
@property (nonatomic) BOOL required;
@property (nonatomic, assign) LibraryEmailFormViewController *formViewController;
@property (nonatomic, assign) id<LibraryFormElementDelegate> delegate;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel displayLabelSubtitle:(NSString *)displayLabelSubtitle required:(BOOL)required;

- (void)updateCell:(UITableViewCell *)tableViewCell;
- (UITableViewCell *)tableViewCell;
- (CGFloat)heightForTableViewCell;
- (UIView *)textInputView;
- (NSString *)value;
@end

@interface MenuLibraryFormElement : LibraryFormElement {
@private
    NSInteger _currentOptionIndex;
}

@property (nonatomic, assign) NSInteger currentOptionIndex;
@property (nonatomic, retain) NSArray *options;
@property (nonatomic, retain) NSArray *displayOptions;
@property (nonatomic, retain) NSString *value;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values displayValues:(NSArray *)displayValues;

@end

NSString* placeholderText(NSString *displayLabel, BOOL required);

@interface TextLibraryFormElement : LibraryFormElement <UITextFieldDelegate> {
@private
}

@property (nonatomic, retain) UITextField *textField;
@property (assign) UIKeyboardType keyboardType;

@end

@interface TextAreaLibraryFormElement : LibraryFormElement {
@private
}

@property (nonatomic, retain) PlaceholderTextView *textView;
@end


@interface DedicatedViewTextLibraryFormElement : LibraryFormElement {
@private
    NSString *textValue_;
}

@property (nonatomic, retain) NSString *textValue;

@end

@interface ExternalLinkLibraryFormElement : LibraryFormElement
@property (nonatomic, retain) NSURL *url;
@end


@interface LibraryFormElementGroup : NSObject {
@private
    NSArray *formElements;
    LibraryEmailFormViewController *_formViewController;
}

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

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *headerText;
@property (nonatomic, retain) NSString *footerText;
@property (nonatomic) BOOL hidden;
@property (nonatomic, assign) LibraryEmailFormViewController *formViewController;

- (NSString *)getFormValueForKey:(NSString *)key;

@end


@interface LibraryEmailFormViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate> {
@private    
    NSArray *_formGroups;
    BOOL identityVerified;
}

- (NSArray *)formGroups;

- (NSString *)command;


@property (nonatomic, retain) MITLoadingActivityView *loadingView;
@property (nonatomic, retain) UISegmentedControl *prevNextSegmentedControl;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, readonly, retain) UIView *formInputAccessoryView;
@property (nonatomic, retain) UIResponder *currentTextView;

- (NSDictionary *)formValues;

- (LibraryFormElementGroup *)groupForName:(NSString *)name;
- (LibraryFormElement *)statusMenuFormElementWithRequired:(BOOL)required;

@end
