#import "MITModule.h"

@class CampusMapViewController;

@interface CMModule : MITModule {

	CampusMapViewController* _campusMapVC;
}

@property (nonatomic, retain) CampusMapViewController* campusMapVC;

@end
