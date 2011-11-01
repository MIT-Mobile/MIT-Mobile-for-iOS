
#import "LibrariesAppointmentViewController.h"


@implementation LibrariesAppointmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Appointment";
}

- (NSString *)command {
    return @"sendAskUsEmail"; 
}

- (NSArray *)formGroups {
    TextLibraryFormElement *phoneElement = 
    [[[TextLibraryFormElement alloc] 
      initWithKey:@"phone" displayLabel:@"Phone Number" required:NO] 
     autorelease];
    phoneElement.keyboardType = UIKeyboardTypePhonePad;

    return [NSArray arrayWithObjects:
        [LibraryFormElementGroup groupForName:@"Question" elements:[NSArray arrayWithObjects:
                                                                    // Temporary.
            [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"subject" 
                                            displayLabel:@"Topic of your research" 
                                                required:YES] autorelease],
            
            [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"timeframe" 
                                            displayLabel:@"Timeframe for your research:" 
                                                required:YES] autorelease],
                                                                    
            [[[TextAreaLibraryFormElement alloc] initWithKey:@"description" 
                                            displayLabel:@"How can we help you?" 
                                        displayLabelSubtitle:@"Describe the information you're looking for and the research you've already done."
                                                required:YES] autorelease],
                                                                    
            [[[MenuLibraryFormElement alloc] initWithKey:@"why" 
                                            displayLabel:@"Purpose of research:" 
                                                required:NO 
                                                  values:[NSArray arrayWithObjects:@"Course", @"Thesis", @"Research", nil]] autorelease],
                                                                    
            [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"course" 
                                            displayLabel:@"Which course?" 
                                                required:NO] autorelease],
                                                                    
            [[[MenuLibraryFormElement alloc] initWithKey:@"topic" 
                                            displayLabel:@"I would like to discuss" 
                                                required:YES 
                                                  values:[NSArray arrayWithObjects:
                                                          @"General",
                                                          @"Art, Architecture & Planning",
                                                          @"Engineering & Computer Science",
                                                          @"GIS",
                                                          @"Humanities",
                                                          @"Management & Business",
                                                          @"Science",
                                                          @"Social Sciences",
                                                          @"Urban Planning", nil]] autorelease],
                                                                
            nil]],
        
        [LibraryFormElementGroup groupForName:@"PersonalInfo" elements:[NSArray arrayWithObjects:
            [self statusMenuFormElementWithRequired:YES],            
            [[[TextLibraryFormElement alloc] initWithKey:@"department" displayLabel:@"Your department" required:YES] autorelease],
            phoneElement,
            nil]],
        
        nil];
}
@end
