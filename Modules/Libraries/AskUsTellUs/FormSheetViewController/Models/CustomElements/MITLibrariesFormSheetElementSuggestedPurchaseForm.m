#import "MITLibrariesFormSheetElementSuggestedPurchaseForm.h"

@implementation MITLibrariesFormSheetElementSuggestedPurchaseForm
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = MITLibrariesFormSheetElementTypeWebLink;
        self.title = @"Suggested Purchase Form";
        self.value = @"http://libraries.mit.edu/suggest-purchase";
    }
    return self;
}
@end
