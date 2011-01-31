#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITThumbnailView.h"
#import "IconGrid.h"

@class FeatureLink;

@interface MIT150ViewController : UITableViewController <JSONLoadedDelegate, IconGridDelegate> {

}

- (void)showWelcome;
- (void)showCorridor;

@end

@interface MIT150Button : UIControl <MITThumbnailDelegate>
{
    FeatureLink *_featureLink;
}

@property (nonatomic, retain) FeatureLink *featureLink;

@end