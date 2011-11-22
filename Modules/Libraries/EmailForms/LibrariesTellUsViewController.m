
#import "LibrariesTellUsViewController.h"


@implementation LibrariesTellUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tell Us!";
}

- (NSString *)command {
    return @"sendTellUsEmail";
}

- (NSArray *)formGroups {
    LibraryFormElementGroup *feedbackGroup = 
    [LibraryFormElementGroup groupForName:nil
                                 elements:[NSArray arrayWithObjects:
                                           [self statusMenuFormElementWithRequired:NO],
                                           [[[TextAreaLibraryFormElement alloc] 
                                             initWithKey:@"feedback" 
                                             displayLabel:@"Feedback" 
                                             required:YES] autorelease],
                                           nil]];
    
    feedbackGroup.footerText = @"Please let us know your thoughts for improving our services. We'd also appreciate hearing what you like about our current services."
    "\n"
    "\n"
    "If you would like to suggest a purchase for our collections, please see the Suggested Purchase form.";
    return [NSArray arrayWithObject:feedbackGroup];
}

@end
