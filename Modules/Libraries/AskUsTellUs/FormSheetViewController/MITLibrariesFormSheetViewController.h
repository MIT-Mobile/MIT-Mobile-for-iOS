
#import <UIKit/UIKit.h>
#import "MITLibrariesFormSheetGroup.h"
#import "MITLibrariesFormSheetElement.h"
#import "MITLibrariesFormSheetOptionsSelectionViewController.h"

@interface MITLibrariesFormSheetViewController : UIViewController <MITLibrariesFormSheetOptionsSelectionViewControllerDelegate>
@property (nonatomic, strong) NSArray *formSheetGroups;
- (void)reloadTableView;
- (void)setup;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (void)closeFormSheetViewController;
- (void)submitFormForParameters:(NSDictionary *)parameters;
- (void)notifyFormSubmissionError;
- (void)notifyFormSubmissionSuccessWithResponseObject:(id)responseObject;
@end
