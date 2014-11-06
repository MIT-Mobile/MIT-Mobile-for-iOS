
#import <UIKit/UIKit.h>
#import "MITLibrariesFormSheetCellProtocol.h"

extern NSString * const MITLibrariesFormSheetCellSingleLineTextEntryNibName;

@interface MITLibrariesFormSheetCellSingleLineTextEntry : UITableViewCell <MITLibrariesFormSheetTextEntryCellProtocol>
@property (weak, nonatomic) id<MITLibrariesFormSheetTextEntryCellDelegate>delegate;
@end
