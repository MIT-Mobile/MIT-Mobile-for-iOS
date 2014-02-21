#import "LibrariesAppointmentViewController.h"
#import "UIKit+MITAdditions.h"
#import "LibraryFormElements.h"

@interface LibrariesAppointmentViewController ()

@property (nonatomic,copy) NSArray *formGroups;

@end

@implementation LibrariesAppointmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Appointment";
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

- (NSArray *)formGroups {
    LibraryFormElementGroup *researchGroup = nil;
    if (!_formGroups) {
        {
            DedicatedViewTextLibraryFormElement *subjectElement = [[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"subject"
                                                                                                              displayLabel:@"Topic"
                                                                                                                  required:YES];
            
            DedicatedViewTextLibraryFormElement *timeframeElement = [[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"timeframe"
                                                                                                               displayLabel:@"Timeframe"
                                                                                                                   required:YES];
            TextAreaLibraryFormElement *descriptionTextElement = [[TextAreaLibraryFormElement alloc] initWithKey:@"description"
                                                                                                    displayLabel:@"How can we help you?"
                                                                                                        required:YES];
            
            MenuLibraryFormElement *purposeMenuElement = [[MenuLibraryFormElement alloc] initWithKey:@"why"
                                                                                        displayLabel:@"Purpose"
                                                                                            required:NO
                                                                                              values:@[@"Course", @"Thesis", @"Research"]];
            
            DedicatedViewTextLibraryFormElement *courseElement = [[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"course"
                                                                                                             displayLabel:@"Course"
                                                                                                                    required:NO];
            
            NSArray *topics = @[@"General", @"Art & Architecture", @"Engineering & Computer Science",
                               @"GIS", @"Humanities", @"Management & Business", @"Science",
                               @"Social Sciences", @"Urban Planning"];
            MenuLibraryFormElement *topicMenuElement = [[MenuLibraryFormElement alloc] initWithKey:@"topic"
                                                                                      displayLabel:@"Subject"
                                                                                          required:YES
                                                                                            values:topics];
            
            researchGroup = [LibraryFormElementGroup groupForName:@"Research Info"
                                                         elements:@[subjectElement,
                                                                    timeframeElement,
                                                                    descriptionTextElement,
                                                                    purposeMenuElement,
                                                                    courseElement,
                                                                    topicMenuElement]];
            researchGroup.footerText = @"Your request will be sent to the appropriate person, based on your choice of subject.";
        }
        
        
        LibraryFormElementGroup *contactInfoGroup = nil;
        {
            TextLibraryFormElement *departmentElement = [[TextLibraryFormElement alloc] initWithKey:@"department"
                                                                                       displayLabel:@"Department, Lab, or Center"
                                                                                           required:YES];
            
            TextLibraryFormElement *phoneElement =  [[TextLibraryFormElement alloc] initWithKey:@"phone"
                                                                                   displayLabel:@"Phone"
                                                                                       required:NO];
            phoneElement.keyboardType = UIKeyboardTypePhonePad;
            
            contactInfoGroup = [LibraryFormElementGroup groupForName:@"Personal Info"
                                                            elements:@[[self statusMenuFormElementWithRequired:YES],
                                                                       departmentElement,
                                                                       phoneElement]];
        }
        
        
        _formGroups = @[researchGroup,contactInfoGroup];
    }
    return _formGroups;
}
                                                 
@end
