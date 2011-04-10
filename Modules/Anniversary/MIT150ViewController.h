#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"


@class FeatureLink;

@interface MIT150ViewController : UITableViewController <JSONLoadedDelegate> {

    NSArray *featuredButtonGroups;
    CGSize buttonMargins;
}

- (void)showWelcome;
- (void)showCorridor;

@property (nonatomic, retain) NSArray *featuredButtonGroups;
@property (nonatomic, assign) CGSize buttonMargins;

@end
