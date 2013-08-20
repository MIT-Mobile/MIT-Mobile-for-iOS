
#import <UIKit/UIKit.h>

@class MITMapSearchResultAnnotation;
@class CampusMapViewController;

@interface MITMapDetailViewController : UIViewController

@property (nonatomic, strong) MITMapSearchResultAnnotation* annotation;
@property (nonatomic, strong) MITMapSearchResultAnnotation* annotationDetails;
@property (nonatomic, weak) CampusMapViewController* campusMapVC;
@property (nonatomic, copy) NSString* queryText;
@property int startingTab;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;

// user tapped the bookmark/favorite button
-(IBAction) bookmarkButtonTapped;

@end
