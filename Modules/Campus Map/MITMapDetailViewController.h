
#import <UIKit/UIKit.h>
#import "TabViewControl.h"
#import "MITMapView.h"
#import "ConnectionWrapper.h"


@class MITMapSearchResultAnnotation;
@class CampusMapViewController;

@interface MITMapDetailViewController : UIViewController <ConnectionWrapperDelegate, TabViewControlDelegate, JSONLoadedDelegate, MITMapViewDelegate>

@property (nonatomic, retain) MITMapSearchResultAnnotation* annotation;
@property (nonatomic, retain) MITMapSearchResultAnnotation* annotationDetails;

@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@property (nonatomic, retain) NSString* queryText;

@property (nonatomic, retain) ConnectionWrapper *imageConnectionWrapper;
@property int startingTab;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;

// user tapped the bookmark/favorite button
-(IBAction) bookmarkButtonTapped;

@end
