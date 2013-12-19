
#import <UIKit/UIKit.h>

@class MITMapPlace;

@interface MITMapDetailViewController : UIViewController

@property (nonatomic, strong) MITMapPlace* place;
@property (nonatomic, copy) NSString* queryText;
@property int startingTab;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;

// user tapped the bookmark/favorite button
-(IBAction) bookmarkButtonTapped;

@end
