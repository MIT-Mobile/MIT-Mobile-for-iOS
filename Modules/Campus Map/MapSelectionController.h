#import <Foundation/Foundation.h>

@class CampusMapViewController;

typedef enum {
	MapSelectionControllerSegmentBookmarks = 0,
	MapSelectionControllerSegmentRecents,
	MapSelectionControllerSegmentBrowse,
} MapSelectionControllerSegment;


@interface MapSelectionController : UINavigationController 
{
	NSArray* _toolbarButtonItems;
	
	CampusMapViewController* _mapVC;
	
	UIBarButtonItem* _cancelButton;
}

@property(nonatomic, readonly) NSArray* toolbarButtonItems;
@property(nonatomic, readonly) CampusMapViewController* mapVC;
@property(nonatomic, readonly) UIBarButtonItem* cancelButton;

-(id) initWithMapSelectionControllerSegment:(MapSelectionControllerSegment) segment campusMap:(CampusMapViewController*)mapVC;


@end
