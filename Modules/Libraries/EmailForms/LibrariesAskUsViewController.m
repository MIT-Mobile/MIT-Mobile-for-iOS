#import "LibrariesAskUsViewController.h"


@implementation TopicsMenuLibraryFormElement

+ (TopicsMenuLibraryFormElement *)formElement {
    TopicsMenuLibraryFormElement *element = [[[TopicsMenuLibraryFormElement alloc] initWithKey:@"topic"
                                                 displayLabel:@"Topic Area:"
                                                     required:YES 
                                                       values:[NSArray arrayWithObjects:
                                                               @"Art, Architecture & Planning", 
                                                               @"Engineering & Computer Science",
                                                               @"Management & Business",
                                                               @"Science",
                                                               @"Social Sciences",
                                                               @"General",
                                                               @"Circulation",
                                                               @"Technical Help",
                                                               nil] 
                                                  placeHolder:@"Select a topic area"] autorelease];
    element.onChangeJavaScript = @"document.getElementById('TechHelp').style.display = (this.value == 'Technical Help') ? '' : 'none'";
    return element;
}

@end
@implementation LibrariesAskUsViewController

- (NSArray *)formGroups {
    return [NSArray arrayWithObjects:
        [LibraryFormElementGroup groupForName:@"Question" elements:[NSArray arrayWithObjects:
            [TopicsMenuLibraryFormElement formElement],
            
            [[[TextLibraryFormElement alloc] initWithKey:@"subject" 
                                            displayLabel:@"Subject line:" 
                                                required:YES] autorelease],
            
            [[[TextAreaLibraryFormElement alloc] initWithKey:@"question" 
                                            displayLabel:@"Detailed question:" 
                                                required:YES] autorelease],
                                    
            nil]],
            
         [LibraryFormElementGroup hiddenGroupForName:@"TechHelp" elements:[NSArray arrayWithObjects:
            [[[RadioLibraryFormElement alloc] initWithKey:@"on_campus"
                                             displayLabel:@"Is the problem happening on or off campus?"
                                                 required:YES 
                                                   values:[NSArray arrayWithObjects:@"on campus", @"off campus", nil] 
                                            displayValues:[NSArray arrayWithObjects:@"On campus", @"Off campus", nil]] autorelease],

            [[[RadioLibraryFormElement alloc] initWithKey:@"vpn"
                                             displayLabel:@"Are you using VPN?"
                                                 required:YES 
                                                   values:[NSArray arrayWithObjects:@"yes", @"no", nil] 
                                            displayValues:[NSArray arrayWithObjects:@"Yes", @"No", nil]] autorelease],
                                                                           
            nil]],
                                                                             
            
         [LibraryFormElementGroup groupForName:@"PersonalInfo" elements:[NSArray arrayWithObjects:
            [self statusMenuFormElement],            
            [[[TextLibraryFormElement alloc] initWithKey:@"department" displayLabel:@"Your department" required:YES] autorelease],
            [[[TextLibraryFormElement alloc] initWithKey:@"phone" displayLabel:@"Phone Number" required:NO] autorelease],
            
            nil]],
        nil];
}


- (NSString *)command {
    return @"sendAskUsEmail"; 
}

- (BOOL)populateFormValues:(NSMutableDictionary *)formValues {
        BOOL allRequiredFieldsPresent = YES;
        for (LibraryFormElementGroup *formGroup in [self formGroups]) {
            for (NSString *key in [formGroup keys]) {
                NSString *value = [self getFormValueForKey:key];
                
                // skip the TechHelp section if not selected for topic
                if ([formGroup.name isEqualToString:@"TechHelp"] && ![[self getFormValueForKey:@"topic"] isEqualToString:@"Technical Help"]) {
                     continue;
                }
                     
                if ([formGroup valueRequiredForKey:key]) {
                    if ([value length]) {
                        [self markValueAsPresentForKey:key];
                    } else {
                        [self markValueAsMissingForKey:key];
                        allRequiredFieldsPresent = NO;
                    }
                }
                [formValues setObject:value forKey:key];
                
            }
        }
    
    if (allRequiredFieldsPresent) {
        [formValues setObject:@"form" forKey:@"ask_type"];
    }
    return allRequiredFieldsPresent;
}

@end
