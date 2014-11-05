
#import <Foundation/Foundation.h>

@class MITLibrariesFormSheetElement;
@protocol MITLibrariesFormSheetCellProtocol <NSObject>
- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element;
+ (CGFloat)heightForCell;
@end
