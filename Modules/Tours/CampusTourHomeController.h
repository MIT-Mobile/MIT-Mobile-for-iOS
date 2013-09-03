#import <UIKit/UIKit.h>
#import "ToursDataManager.h"

@class ScrollFadeImageView;

@interface CampusTourHomeController : UIViewController <UITableViewDelegate, UITableViewDataSource>
- (void)tourInfoLoaded:(NSNotification *)aNotification;
- (void)tourInfoFailedToLoad:(NSNotification *)aNotification;

@property (nonatomic, copy) NSArray *tours;

@end
