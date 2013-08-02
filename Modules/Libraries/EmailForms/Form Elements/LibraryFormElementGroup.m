#import "LibraryFormElementGroup.h"
#import "LibraryFormElement.h"

@interface LibraryFormElementGroup ()
@property (copy) NSArray *formElements;
@end

@implementation LibraryFormElementGroup
+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements {
    return [[LibraryFormElementGroup alloc] initWithName:name formElements:elements];
}

+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements {
    LibraryFormElementGroup *group = [[LibraryFormElementGroup alloc] initWithName:name formElements:elements];
    group.hidden = YES;
    return group;
}

- (id)initWithName:(NSString *)aName formElements:(NSArray *)theFormElements {
    self = [super init];
    
    if (self) {
        _formElements = [theFormElements copy];
        _name = aName;
    }
    
    return self;
}

- (NSArray *)textInputViews {
    NSMutableArray *textInputViews = [NSMutableArray array];
    for (LibraryFormElement *formElement in self.formElements) {
        if ([formElement textInputView]) {
            [textInputViews addObject:[formElement textInputView]];
        }
    }
    return textInputViews;
}

- (BOOL)valueRequiredForKey:(NSString *)key {
    for(LibraryFormElement *formElement in self.formElements) {
        if ([key isEqual:formElement.key]) {
            return formElement.required;
        }
    }
    
    DDLogError(@"Key '%@' not found in group '%@'", key, self.name);
    return NO;
}

- (NSString *)getFormValueForKey:(NSString *)key {
    for(LibraryFormElement *formElement in self.formElements) {
        if ([key isEqual:formElement.key]) {
            return [[formElement value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
        }
    }
    
    DDLogError(@"Key '%@' not found in group '%@'", key, self.name);
    return nil;
}


- (NSArray *)keys {
    NSMutableArray *keys = [NSMutableArray array];
    for(LibraryFormElement *formElement in self.formElements) {
        [keys addObject:formElement.key];
    }
    
    return keys;
}

- (NSArray *)elements {
    return self.formElements;
}

- (NSString *)keyForRow:(NSInteger)row {
    return [[self keys] objectAtIndex:row];
}

- (LibraryFormElement *)formElementForKey:(NSString *)key {
    for(LibraryFormElement *formElement in self.formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement;
        }
    }
    return nil;
}

- (NSInteger)numberOfRows {
    return [self.formElements count];
}

- (void)setFormViewController:(LibraryEmailFormViewController *)aFormViewController {
    if (aFormViewController) {
        for(LibraryFormElement *element in self.formElements) {
            element.formViewController = aFormViewController;
        }
    }
    
    _formViewController = aFormViewController;
}

@end
