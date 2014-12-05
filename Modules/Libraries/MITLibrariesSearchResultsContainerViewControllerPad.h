#import <UIKit/UIKit.h>
#import "MITLibrariesHomeViewControllerPad.h"

@protocol MITLibrariesSearchResultsViewControllerDelegate;
@interface MITLibrariesSearchResultsContainerViewControllerPad : UIViewController 

@property (nonatomic, assign) MITLibrariesLayoutMode layoutMode;
@property (nonatomic, weak) id<MITLibrariesSearchResultsViewControllerDelegate> delegate;

- (void)search:(NSString *)searchTerm;

@end
