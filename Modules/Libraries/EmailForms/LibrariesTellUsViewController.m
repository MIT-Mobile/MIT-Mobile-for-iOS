
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
    return [NSArray arrayWithObject:
            [LibraryFormElementGroup 
             groupForName:nil
             elements:[NSArray arrayWithObjects:
                       [self statusMenuFormElementWithRequired:NO],
                       [[[TextAreaLibraryFormElement alloc] 
                         initWithKey:@"feedback" 
                         displayLabel:@"Feedback" 
                         required:YES] autorelease],
                       nil]]];
}

@end
