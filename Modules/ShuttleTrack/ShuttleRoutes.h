#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"


//@class ShuttleData;

@interface ShuttleRoutes : UITableViewController <ShuttleDataManagerDelegate>

@property (nonatomic, copy) NSArray* shuttleRoutes;               // complete list of shuttle routes.
@property (nonatomic, copy) NSArray* saferideRoutes;              // routes that were flagged as saferide
@property (nonatomic, copy) NSArray* nonSaferideRoutes;           // routes that  were not flagged as saferide
@property (nonatomic, copy) NSArray* sections;                    // sections for display in the table view. Sections include title and routes
@property BOOL isLoading;                                           // flag indicating whether we are waiting for data to finish loading from the web service


//@property (readwrite, retain) ShuttleData *model;

@end
