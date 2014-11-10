#import "MITLibrariesFormSheetGroupTellUsTopGroup.h"
#import "MITLibrariesFormSheetElementCustomElementsHeader.h"

@implementation MITLibrariesFormSheetGroupTellUsTopGroup
- (instancetype)init
{
    self = [super init];
    if (self) {
        MITLibrariesFormSheetElementStatus *status = [MITLibrariesFormSheetElementStatus new];
        MITLibrariesFormSheetElement *feedback = [MITLibrariesFormSheetElementFeedback new];
        
        self.headerTitle = nil;
        self.footerTitle = @"Please let us know your thoughts for improving our services.  We'd also appreciate hearing what you like about our current services.";
        self.elements = @[status, feedback];
    }
    return self;
}
@end
