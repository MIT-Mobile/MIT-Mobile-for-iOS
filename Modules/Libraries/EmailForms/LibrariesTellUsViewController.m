
#import "LibrariesTellUsViewController.h"


@implementation LibrariesTellUsViewController

- (NSString *)command {
    return @"sendTellUsEmail";
}

- (NSArray *)formGroups {
    return [NSArray arrayWithObject:
            [LibraryFormElementGroup 
             groupForName:@"main"
             elements:[NSArray arrayWithObjects:
                       [self statusMenuFormElementWithRequired:NO],
                       [[[TextAreaLibraryFormElement alloc] 
                         initWithKey:@"feedback" 
                         displayLabel:@"Feedback" 
                         required:YES] autorelease],
                       nil]]];
}

@end
