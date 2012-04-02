
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
      initWithKey:@"phone" displayLabel:@"Phone" required:NO] 
     autorelease];
    phoneElement.keyboardType = UIKeyboardTypePhonePad;
    
    LibraryFormElementGroup *researchGroup =
    [LibraryFormElementGroup groupForName:@"Research Info" elements:
     [NSArray arrayWithObjects:
      [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"subject" 
                                                   displayLabel:@"Topic" 
                                                       required:YES] autorelease],
      
      [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"timeframe" 
                                                   displayLabel:@"Timeframe" 
                                                       required:YES] autorelease],
      
      [[[TextAreaLibraryFormElement alloc] initWithKey:@"description" 
                                          displayLabel:@"How can we help you?"
                                              required:YES] autorelease],
      
      [[[MenuLibraryFormElement alloc] initWithKey:@"why" 
                                      displayLabel:@"Purpose" 
                                          required:NO 
                                            values:[NSArray arrayWithObjects:@"Course", @"Thesis", @"Research", nil]] autorelease],
      
      [[[DedicatedViewTextLibraryFormElement alloc] initWithKey:@"course" 
                                                   displayLabel:@"Course" 
                                                       required:NO] autorelease],
      
      [[[MenuLibraryFormElement alloc] initWithKey:@"topic" 
                                      displayLabel:@"Subject" 
                                          required:YES 
                                            values:[NSArray arrayWithObjects:
                                                    @"General",
                                                    @"Art & Architecture",
                                                    @"Engineering & Computer Science",
                                                    @"GIS",
                                                    @"Humanities",
                                                    @"Management & Business",
                                                    @"Science",
                                                    @"Social Sciences",
                                                    @"Urban Planning", nil]] autorelease],
      
      nil]];
    
    researchGroup.footerText = @"Your request will be sent to the appropriate person, based on your choice of subject.";
    
    return [NSArray arrayWithObjects:
        researchGroup,
            
        [LibraryFormElementGroup groupForName:@"Personal Info" elements:[NSArray arrayWithObjects:
            [self statusMenuFormElementWithRequired:YES],            
            [[[TextLibraryFormElement alloc] initWithKey:@"department" displayLabel:@"Department, Lab, or Center" required:YES] autorelease],
            phoneElement,
            nil]],
        
        nil];
}
@end
