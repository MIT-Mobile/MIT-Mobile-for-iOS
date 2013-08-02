#import "LibraryFormElementGroup.h"

@implementation LibraryFormElementGroup
@synthesize name;
@synthesize headerText;
@synthesize footerText;
@synthesize hidden;

+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements {
    return [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
}

+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements {
    LibraryFormElementGroup *group = [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
    group.hidden = YES;
    return group;
}

- (id)initWithName:(NSString *)aName formElements:(NSArray *)theFormElements {
    self = [super init];
    if (self) {
        formElements = [theFormElements retain];
        self.name = aName;
    }
    return self;
}

- (NSArray *)textInputViews {
    NSMutableArray *textInputViews = [NSMutableArray array];
    for (LibraryFormElement *formElement in formElements) {
        if ([formElement textInputView]) {
            [textInputViews addObject:[formElement textInputView]];
        }
    }
    return textInputViews;
}

- (void)dealloc {
    [formElements release];
    self.name = nil;
    [super dealloc];
}

- (BOOL)valueRequiredForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement.required;
        }
    }
    
    [NSException raise:@"key not found in form" format:@"%@ not found in group", key];
    return NO;
}

- (NSString *)getFormValueForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return [[formElement value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
        }
    }
    
    [NSException raise:@"key not found in form" format:@"%@ not found in group", key];
    return nil;
    
}


- (NSArray *)keys {
    NSMutableArray *keys = [NSMutableArray array];
    for(LibraryFormElement *formElement in formElements) {
        [keys addObject:formElement.key];
    }
    return keys;
}

- (NSArray *)elements {
    return formElements;
}

- (NSString *)keyForRow:(NSInteger)row {
    return [[self keys] objectAtIndex:row];
}

- (LibraryFormElement *)formElementForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement;
        }
    }
    return nil;
}


- (NSInteger)numberOfRows {
    return formElements.count;
}

- (void)setFormViewController:(LibraryEmailFormViewController *)aFormViewController {
    if (aFormViewController) {
        for(LibraryFormElement *element in formElements) {
            element.formViewController = aFormViewController;
        }
    }
    
    _formViewController = aFormViewController;
}

- (LibraryEmailFormViewController *)formViewController {
    return _formViewController;
}

@end
