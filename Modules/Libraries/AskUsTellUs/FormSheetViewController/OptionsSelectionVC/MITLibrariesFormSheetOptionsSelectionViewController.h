#import <UIKit/UIKit.h>

@class MITLibrariesFormSheetOptionsSelectionViewController, MITLibrariesFormSheetElement;
@protocol MITLibrariesFormSheetOptionsSelectionViewControllerDelegate <NSObject>
- (void)formSheetOptionsSelectionViewController:(MITLibrariesFormSheetOptionsSelectionViewController *)optionsSelectionViewController didFinishUpdatingElement:(MITLibrariesFormSheetElement *)element;
@end
@interface MITLibrariesFormSheetOptionsSelectionViewController : UIViewController
@property (nonatomic, strong) MITLibrariesFormSheetElement *element;
@property (nonatomic, weak) id<MITLibrariesFormSheetOptionsSelectionViewControllerDelegate>delegate;
@end
