
#import <UIKit/UIKit.h>

@class MITMapPlace;
@class CampusMapViewController;

@interface MITMapDetailViewController : UIViewController

@property (nonatomic, strong) MITMapPlace* place;
@property (nonatomic, weak) CampusMapViewController* campusMapVC;
@property (nonatomic, copy) NSString* queryText;
@property int startingTab;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;

// user tapped the bookmark/favorite button
-(IBAction) bookmarkButtonTapped;

@end
