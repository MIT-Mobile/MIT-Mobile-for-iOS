#import <UIKit/UIKit.h>
#import "LibraryEmailFormViewController.h"

@interface LibrariesAskUsViewController : LibraryEmailFormViewController <LibraryFormElementDelegate> {
    BOOL techHelpSectionHidden;
}

@end


@interface TopicsMenuLibraryFormElement : MenuLibraryFormElement {
@private
    
}

+ (TopicsMenuLibraryFormElement *)formElementWithDelegate:(id<LibraryFormElementDelegate>) delegate;

@end
