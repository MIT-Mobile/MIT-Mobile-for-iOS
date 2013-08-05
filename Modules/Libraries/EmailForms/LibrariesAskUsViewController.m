#import "LibrariesAskUsViewController.h"
#import "UIKit+MITAdditions.h"
#import "LibraryFormElements.h"

@interface LibrariesAskUsViewController () <LibraryFormElementDelegate>
@property BOOL techHelpSectionHidden;
@end

@implementation LibrariesAskUsViewController

- (NSArray *)formGroups {
    LibraryFormElementGroup *questionGroup = nil;
    {
        TopicsMenuLibraryFormElement *formElement = [TopicsMenuLibraryFormElement formElementWithDelegate:self];
        TextLibraryFormElement *subjectElement = [[TextLibraryFormElement alloc] initWithKey:@"subject"
                                                                                displayLabel:@"Subject"
                                                                                    required:YES];
        TextAreaLibraryFormElement *questionElement = [[TextAreaLibraryFormElement alloc] initWithKey:@"question"
                                                                                         displayLabel:@"Detailed question"
                                                                                             required:YES];
        questionGroup = [LibraryFormElementGroup groupForName:nil
                                                     elements:@[formElement,subjectElement, questionElement]];
    }
    
    
    LibraryFormElementGroup *technicalGroup = nil;
    {
        MenuLibraryFormElement *vpnElement = [[MenuLibraryFormElement alloc] initWithKey:@"vpn"
                                                                            displayLabel:@"Using VPN"
                                                                                required:YES
                                                                                  values:@[@YES,@NO]
                                                                           displayValues:@[@"Yes", @"No"]];
        vpnElement.value = @"no";
        
        
        MenuLibraryFormElement *locationElement = [[MenuLibraryFormElement alloc] initWithKey:@"on_campus"
                                                                                 displayLabel:@"Location"
                                                                                     required:YES
                                                                                       values:@[@"on campus",@"off campus"]
                                                                                displayValues:@[@"On campus",@"Off campus"]];
        technicalGroup = [LibraryFormElementGroup hiddenGroupForName:@"Technical Help"
                                                            elements:@[vpnElement,locationElement]];
    }
    
    LibraryFormElementGroup *personalGroup = nil;
    {
        
        TextLibraryFormElement *phoneElement = [[TextLibraryFormElement alloc] initWithKey:@"phone"
                                                                              displayLabel:@"Phone"
                                                                                  required:NO];
        phoneElement.keyboardType = UIKeyboardTypePhonePad;
        
        TextLibraryFormElement *departmentElement = [[TextLibraryFormElement alloc] initWithKey:@"department"
                                                                                   displayLabel:@"Department, Lab, or Center"
                                                                                       required:YES];
        
        personalGroup = [LibraryFormElementGroup groupForName:@"Personal Info"
                                                     elements:@[[self statusMenuFormElementWithRequired:YES],
                                                                departmentElement,
                                                                phoneElement]];

    }
    
    return @[questionGroup, technicalGroup, personalGroup];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.techHelpSectionHidden = YES;
    self.title = @"Ask Us!";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    LibraryFormElementGroup *techFormGroup = [self groupForName:@"Technical Help"];
    if (self.techHelpSectionHidden != techFormGroup.hidden) {
        NSIndexSet *techHelpSection = [NSIndexSet indexSetWithIndex:1];
        techFormGroup.hidden = self.techHelpSectionHidden;
        if (techFormGroup.hidden) {
            [self.tableView deleteSections:techHelpSection withRowAnimation:UITableViewRowAnimationTop];
        } else {
            [self.tableView insertSections:techHelpSection withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (NSString *)command {
    return @"sendAskUsEmail"; 
}

- (NSDictionary *)formValues {
    NSMutableDictionary *values = [NSMutableDictionary dictionaryWithDictionary:[super formValues]];
    values[@"ask_type"] = @"form";
    return values;
}

- (void)valueChangedForElement:(LibraryFormElement *)element {
    if ([[element value] isEqual:@"Technical Help"]) {
        self.techHelpSectionHidden = NO;
    } else {
        self.techHelpSectionHidden = YES;
    }
}

@end
