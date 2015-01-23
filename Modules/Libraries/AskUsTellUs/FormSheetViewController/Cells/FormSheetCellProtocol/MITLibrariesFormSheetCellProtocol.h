#import <Foundation/Foundation.h>

@class MITLibrariesFormSheetElement;
@protocol MITLibrariesFormSheetCellProtocol <NSObject>
- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element;
+ (CGFloat)heightForCell;
@end

@protocol MITLibrariesFormSheetTextEntryCellDelegate <NSObject>
- (void)textEntryCell:(UITableViewCell *)cell didUpdateValue:(id)value;
@end
@protocol MITLibrariesFormSheetTextEntryCellProtocol <MITLibrariesFormSheetCellProtocol>
@property (weak, nonatomic) id<MITLibrariesFormSheetTextEntryCellDelegate>delegate;
- (void)makeTextEntryFirstResponder;
@end
