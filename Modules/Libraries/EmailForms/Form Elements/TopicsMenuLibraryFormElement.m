#import "TopicsMenuLibraryFormElement.h"

@implementation TopicsMenuLibraryFormElement
+ (TopicsMenuLibraryFormElement *)formElementWithDelegate:(id<LibraryFormElementDelegate>) delegate {
    NSArray *topics = @[@"General",
                        @"Art, Architecture & Planning",
                        @"Engineering & Computer Science",
                        @"Management & Business",
                        @"Science",
                        @"Social Sciences",
                        @"Circulation",
                        @"Technical Help"];
    TopicsMenuLibraryFormElement *element = [[TopicsMenuLibraryFormElement alloc] initWithKey:@"topic"
                                                                                 displayLabel:@"Topic"
                                                                                     required:YES
                                                                                       values:topics];
    element.value = @"General"; // default
    element.delegate = delegate;
    return element;
}

@end

