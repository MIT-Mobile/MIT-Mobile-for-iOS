#import <UIKit/UIKit.h>
#import "MITMapPlaceSelectionDelegate.h"

@interface MITMapBrowseContainerViewController : UIViewController

- (void)setDelegate:(id <MITMapPlaceSelectionDelegate>)delegate;

@end
