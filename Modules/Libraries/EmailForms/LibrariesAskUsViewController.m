#import "LibrariesAskUsViewController.h"


@implementation TopicsMenuLibraryFormElement

+ (TopicsMenuLibraryFormElement *)formElementWithDelegate:(id<LibraryFormElementDelegate>) delegate {
    TopicsMenuLibraryFormElement *element = [[[TopicsMenuLibraryFormElement alloc] initWithKey:@"topic"
                                                 displayLabel:@"Topic"
                                                     required:YES
                                                       values:[NSArray arrayWithObjects:
                                                               @"General",
                                                               @"Art, Architecture & Planning", 
                                                               @"Engineering & Computer Science",
                                                               @"Management & Business",
                                                               @"Science",
                                                               @"Social Sciences",
                                                               @"Circulation",
                                                               @"Technical Help",
                                                               nil]] autorelease];
    element.value = @"General"; // default
    element.delegate = delegate;
    return element;
}

@end
@implementation LibrariesAskUsViewController

- (NSArray *)formGroups {
    
    TextLibraryFormElement *phoneElement = 
    [[[TextLibraryFormElement alloc] 
      initWithKey:@"phone" displayLabel:@"Phone" required:NO] 
     autorelease];
    phoneElement.keyboardType = UIKeyboardTypePhonePad;
    
    MenuLibraryFormElement *vpnElement = 
    [[[MenuLibraryFormElement alloc] initWithKey:@"vpn"
                                    displayLabel:@"Using VPN"
                                        required:YES 
                                          values:[NSArray arrayWithObjects:@"yes", @"no", nil] 
                                   displayValues:[NSArray arrayWithObjects:@"Yes", @"No", nil]] autorelease];
    vpnElement.value = @"no";
    
    LibraryFormElementGroup *questionGroup = [LibraryFormElementGroup 
     groupForName:nil
     elements:[NSArray arrayWithObjects:
               [TopicsMenuLibraryFormElement formElementWithDelegate:self],
               
               [[[TextLibraryFormElement alloc] initWithKey:@"subject" 
                                               displayLabel:@"Subject" 
                                                   required:YES] autorelease],
               
               [[[TextAreaLibraryFormElement alloc] initWithKey:@"question" 
                                                   displayLabel:@"Detailed question" 
                                                       required:YES] autorelease],
               
               nil]];

    LibraryFormElementGroup *technicalGroup = [LibraryFormElementGroup 
     hiddenGroupForName:@"Technical Help" 
     elements:[NSArray arrayWithObjects:
               [[[MenuLibraryFormElement alloc] initWithKey:@"on_campus"
                                               displayLabel:@"Location"
                                                   required:YES 
                                                     values:[NSArray arrayWithObjects:@"on campus", @"off campus", nil] 
                                              displayValues:[NSArray arrayWithObjects:@"On campus", @"Off campus", nil]] autorelease],
               
               vpnElement,
               
               nil]];
    
    LibraryFormElementGroup *personalGroup = [LibraryFormElementGroup 
     groupForName:@"Personal Info" 
     elements:[NSArray arrayWithObjects:
               [self statusMenuFormElementWithRequired:YES],
               [[[TextLibraryFormElement alloc] initWithKey:@"department" displayLabel:@"Department, Lab, or Center" required:YES] autorelease],
               phoneElement,
               nil]];

    
    return [NSArray arrayWithObjects:questionGroup, technicalGroup, personalGroup, nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    techHelpSectionHidden = YES;
    self.title = @"Ask Us!";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    LibraryFormElementGroup *techFormGroup = [self groupForName:@"Technical Help"];
    if (techHelpSectionHidden != techFormGroup.hidden) {
        NSIndexSet *techHelpSection = [NSIndexSet indexSetWithIndex:1];
        techFormGroup.hidden = techHelpSectionHidden;
        if (techFormGroup.hidden) {
            [self.tableView deleteSections:techHelpSection withRowAnimation:UITableViewRowAnimationTop];
        } else {
            [self.tableView insertSections:techHelpSection withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

- (NSString *)command {
    return @"sendAskUsEmail"; 
}

- (NSDictionary *)formValues {
    NSMutableDictionary *values = [NSMutableDictionary dictionaryWithDictionary:[super formValues]];
    [values setObject:@"form" forKey:@"ask_type"];
    return values;
}

- (void)valueChangedForElement:(LibraryFormElement *)element {
    MenuLibraryFormElement *menuElement = (MenuLibraryFormElement *)element;
    if ([[menuElement value] isEqualToString:@"Technical Help"]) {
        techHelpSectionHidden = NO;    
    } else {
        techHelpSectionHidden = YES;
    }
}

@end
