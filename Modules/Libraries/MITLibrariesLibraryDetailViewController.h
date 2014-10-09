#import <UIKit/UIKit.h>

@class MITLibrariesLibrary;

@interface MITLibrariesLibraryDetailViewController : UITableViewController

@property (nonatomic, strong) MITLibrariesLibrary *library;

- (void)dismiss;

@end
