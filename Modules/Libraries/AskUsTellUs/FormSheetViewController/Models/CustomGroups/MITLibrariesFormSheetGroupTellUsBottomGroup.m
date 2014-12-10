#import "MITLibrariesFormSheetGroupTellUsBottomGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupTellUsBottomGroup
- (instancetype)init
{
    self = [super init];
    if (self) {
        MITLibrariesFormSheetElement *suggestedPurchaseForm = [MITLibrariesFormSheetElementSuggestedPurchaseForm new];
        
        self.headerTitle = nil;
        self.footerTitle = @"If you would like to suggest a purchase for our collections, please see the Suggested Purchase form.";
        self.elements = @[suggestedPurchaseForm];
        
    }
    return self;
}
@end
