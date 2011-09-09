#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITLoadingActivityView.h"

@interface LibraryFormElement : NSObject {
@private
}

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *displayLabel;
@property (nonatomic, retain) NSString *displayLabelSubtitle;
@property (nonatomic) BOOL required;
@property (nonatomic, retain) NSString *onChangeJavaScript;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel displayLabelSubtitle:(NSString *)displayLabelSubtitle required:(BOOL)required;
- (NSString *)formHtml;
- (NSString *)labelHtml;

@end

@interface MenuLibraryFormElement : LibraryFormElement {
@private
}

@property (nonatomic, retain) NSString *placeHolder;
@property (nonatomic, retain) NSArray *options;
@property (nonatomic, retain) NSArray *displayOptions;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values placeHolder:(NSString *)placeHolder;
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values displayValues:(NSArray *)displayValues placeHolder:(NSString *)placeHolder;

@end

@interface RadioLibraryFormElement : LibraryFormElement {
@private
}

@property (nonatomic, retain) NSArray *options;
@property (nonatomic, retain) NSArray *displayOptions;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required values:(NSArray *)values displayValues:(NSArray *)displayValues;

@end

@interface TextLibraryFormElement : LibraryFormElement {
@private
}

@end

@interface TextAreaLibraryFormElement : LibraryFormElement {
@private
}

@end

@interface LibraryFormElementGroup : NSObject {
@private
    NSArray *formElements;
}

+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements;
+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements;

- (NSString *)formHtml;
- (BOOL)valueRequiredForKey:(NSString *)key;
- (NSArray *)keys;
- (id)initWithName:(NSString *)name formElements:(NSArray *)formElements;
@property (nonatomic, retain) NSString *name;
@property (nonatomic) BOOL hidden;

@end

/*
@interface TextAreaLibraryFormElement : LibraryFormElement {
@private
}

@end
*/

@interface LibraryEmailFormViewController : UIViewController <UIWebViewDelegate> {
@private    
}

- (NSArray *)formGroups;

- (NSString *)command;


@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) MITLoadingActivityView *loadingView;

- (NSString *)getFormValueForKey:(NSString *)key;
- (void)markValueAsPresentForKey:(NSString *)key;
- (void)markValueAsMissingForKey:(NSString *)key;
- (BOOL)populateFormValues:(NSMutableDictionary *)formValues;

- (LibraryFormElement *)statusMenuFormElement;

@end
