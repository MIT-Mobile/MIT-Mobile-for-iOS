
#import <UIKit/UIKit.h>
#import "MITLibrariesFormSheetGroup.h"
#import "MITLibrariesFormSheetElement.h"
#import "MITLibrariesFormSheetOptionsSelectionViewController.h"

@interface MITLibrariesFormSheetViewController : UIViewController <MITLibrariesFormSheetOptionsSelectionViewControllerDelegate>
@property (nonatomic, strong) NSArray *formSheetGroups;
- (void)reloadTableView;
- (void)submitForm;
- (void)setup;
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (NSDictionary *)formAsHTMLParametersDictionary;
- (void)submitFormForParameters:(NSDictionary *)parameters;
- (void)notifyFormSubmissionError;
- (void)notifyFormSubmissionSuccessWithResponseObject:(id)responseObject;
@end
