#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"
#import "ShuttleSubscriptionManager.h"
#import "MITMapView.h"
#import "MITModuleURL.h"

@class ShuttleStop;
@class ShuttleStopMapAnnotation;
@class ShuttleRoute;

@interface ShuttleStopViewController : UITableViewController <ShuttleDataManagerDelegate, ShuttleSubscriptionDelegate, MITMapViewDelegate> 
{
	// the shuttle stop at which we are looking
	ShuttleStop* _shuttleStop;
	//ShuttleStopLocation *_stopLocation;
	
	// annotation 
	ShuttleStopMapAnnotation* _shuttleStopAnnotation;
		
	// routes that run through this shuttle stop
	//NSDictionary* _routes;
	
	// single route that was selected for display. Can be null if no specific route was selected. 
	//ShuttleRoute* _route;
	
	NSMutableArray* _shuttleStopSchedules;
	
	BOOL _isLoading;
	
	NSDateFormatter* _timeFormatter;
	
	UILabel* _tableFooterLabel;
	
	// the prediction index for which scheduled time has a subscription
	NSMutableDictionary* _subscriptions;
	
	// an array of currently loading subscription requests (by the indexPath for the cell that initiated it)
	NSMutableArray* _loadingSubscriptionRequests;
	
	// map thumbnail
	MITMapView* _mapThumbnail;
	
	// button over the map thumbnail
	UIButton* _mapButton;
	
	NSTimer* _pollingTimer;
	
	MITModuleURL* url;
}


@property (nonatomic, retain) ShuttleStop* shuttleStop;
//@property (nonatomic, retain) ShuttleStopLocation *stopLocation;
@property (nonatomic, assign) ShuttleStopMapAnnotation* annotation;

//@property (nonatomic, retain) NSDictionary* routes;
//@property (nonatomic, retain) ShuttleRoute* route;

@property (nonatomic, retain) NSArray* shuttleStopSchedules;

@property (nonatomic, retain) NSMutableDictionary* subscriptions;
@property (nonatomic, retain) NSMutableArray* loadingSubscriptionRequests;

@property (readonly) UIButton* mapButton;
@end

@interface ShuttlePredictionTableViewCell : UITableViewCell
{
	
}


@end
