
#import <UIKit/UIKit.h>
#import "TabViewControl.h"
#import "MITMapView.h"
#import "PostData.h"


@class MITMapSearchResultAnnotation;
@class CampusMapViewController;

@interface MITMapDetailViewController : UIViewController <TabViewControlDelegate, PostDataDelegate> {

	// tab controller for which we are a delegate.
	IBOutlet TabViewControl* _tabViewControl;
	
	// label for the name
	IBOutlet UILabel* _nameLabel;
	
	// label for the location
	IBOutlet UILabel* _locationLabel;

	// label for the query
	IBOutlet UILabel* _queryLabel;
	
	// container view for the tabbed contents. 
	IBOutlet UIView* _tabViewContainer;
	
	// map view
	IBOutlet MITMapView* _mapView;
	IBOutlet UIButton* _mapViewContainer;

	//
	// BUILDING IMAGE
	//
	
	// view for the building image info
	IBOutlet UIView* _buildingView;
	
	// image view for the building
	IBOutlet UIImageView* _buildingImageView;
	
	// label describing the image
	IBOutlet UILabel* _buildingImageDescriptionLabel;
	
	
	//
	// WHAT's HERE
	// 
	// view for what's here info
	IBOutlet UIView* _whatsHereView;
	
	//
	// LOADING IMAGE VIEW
	//
	IBOutlet UIView* _loadingImageView;
	
	//
	// LOADING RESULT VIEW
	//
	IBOutlet UIView* _loadingResultView;
	
	//
	// MAIN CONTENT SCROLL VIEW
	//
	IBOutlet UIScrollView* _scrollView;
	
	// array of views that appear in our tabs, indexed by tab index. 
	NSMutableArray* _tabViews;
	
	// the search result we are attempting to display
	MITMapSearchResultAnnotation* _annotation;
	
	// updated search result details. Not the annotation we started with, but based on its ID. 
	MITMapSearchResultAnnotation* _annotationDetails;
	
	CampusMapViewController* _campusMapVC;
	
	NSString* _queryText;
	
	CGFloat _tabViewContainerMinHeight;
}

@property (nonatomic, retain) MITMapSearchResultAnnotation* annotation;
@property (nonatomic, retain) MITMapSearchResultAnnotation* annotationDetails;

@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@property (nonatomic, retain) NSString* queryText;

// user tapped on the map thumbnail
-(IBAction) mapThumbnailPressed:(id)sender;


@end
