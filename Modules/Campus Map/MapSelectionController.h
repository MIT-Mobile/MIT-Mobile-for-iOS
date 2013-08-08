#import <Foundation/Foundation.h>

@class CampusMapViewController;

typedef enum {
	MapSelectionControllerSegmentBookmarks = 0,
	MapSelectionControllerSegmentRecents,
	MapSelectionControllerSegmentBrowse,
} MapSelectionControllerSegment;


@interface MapSelectionController : UINavigationController
@property(nonatomic, weak) CampusMapViewController* mapVC;
@property(nonatomic, readonly, strong) UIBarButtonItem* cancelButton;
@property(nonatomic, readonly, copy) NSArray* toolbarButtonItems;

-(id) initWithMapSelectionControllerSegment:(MapSelectionControllerSegment) segment campusMap:(CampusMapViewController*)mapVC;


@end
