
#import <UIKit/UIKit.h>
#import "MITLibrariesFormSheetGroup.h"
#import "MITLibrariesFormSheetElement.h"

@interface MITLibrariesFormSheetViewController : UIViewController
@property (nonatomic, strong) NSArray *formSheetGroups;
- (void)reloadTableView;
- (void)submitForm;
- (void)setup;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
@end
