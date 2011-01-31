#import <UIKit/UIKit.h>
#import "ToursDataManager.h"

@class ScrollFadeImageView;

@interface CampusTourHomeController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    NSArray *tours;
    ScrollFadeImageView *scrollingBackground;
    
    UITableView *_tableView;
    
    BOOL loading;
    BOOL shouldRetry;
}

- (void)tourInfoLoaded:(NSNotification *)aNotification;
- (void)tourInfoFailedToLoad:(NSNotification *)aNotification;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *tours;
@property (nonatomic, retain) ScrollFadeImageView *scrollingBackground;

@end
