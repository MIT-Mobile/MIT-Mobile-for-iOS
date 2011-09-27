#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"


//@class ShuttleData;

@interface ShuttleRoutes : UITableViewController <ShuttleDataManagerDelegate>
{
    //ShuttleData *model;
	
	// complete list of shuttle routes. 
	NSArray* _shuttleRoutes;
	
	// routes that were flagged as saferide
	NSArray* _saferideRoutes;
	
	// routes that  were not flagged as saferide
	NSArray* _nonSaferideRoutes;
	
	// sections for display in the table view. Sections include title and routes
	NSArray* _sections; 
	
	// flag indicating whether we are waiting for data to finish loading from the web service
	BOOL _isLoading;
	
	UIImage* _shuttleRunningImage;
	UIImage* _shuttleNotRunningImage;
	UIImage *_shuttleLoadingImage;

	NSArray* _contactInfo;

	NSArray* _extraLinks;
}

@property (nonatomic, retain) NSArray* shuttleRoutes;
@property (nonatomic, retain) NSArray* saferideRoutes;
@property (nonatomic, retain) NSArray* nonSaferideRoutes;
@property (nonatomic, retain) NSArray* sections;
@property BOOL isLoading;


//@property (readwrite, retain) ShuttleData *model;

@end
