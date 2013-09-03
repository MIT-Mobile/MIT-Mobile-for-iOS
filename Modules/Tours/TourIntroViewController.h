#import <UIKit/UIKit.h>
#import "ToursDataManager.h"

@interface TourIntroViewController : UIViewController <UIWebViewDelegate> {
    
    UIView *_loadingIndicator;

}

- (void)selectStartingLocation;
- (void)tourInfoLoaded:(NSNotification *)aNotification;
- (void)tourInfoFailedToLoad:(NSNotification *)aNotification;

@end
