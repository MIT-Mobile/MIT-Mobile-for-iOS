#import <UIKit/UIKit.h>
#import "MITLibrariesFormSheetCellProtocol.h"

extern NSString * const MITLibrariesFormSheetCellMultiLineTextEntryNibName;

@interface MITLibrariesFormSheetCellMultiLineTextEntry : UITableViewCell <MITLibrariesFormSheetTextEntryCellProtocol>
@property (weak, nonatomic) id<MITLibrariesFormSheetTextEntryCellDelegate>delegate;
@end
