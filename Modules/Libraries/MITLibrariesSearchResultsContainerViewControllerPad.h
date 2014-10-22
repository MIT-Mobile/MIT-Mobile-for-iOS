#import <UIKit/UIKit.h>
#import "MITLibrariesHomeViewControllerPad.h"

@interface MITLibrariesSearchResultsContainerViewControllerPad : UIViewController 

@property (nonatomic, assign) MITLibrariesLayoutMode layoutMode;

- (void)search:(NSString *)searchTerm;

@end
