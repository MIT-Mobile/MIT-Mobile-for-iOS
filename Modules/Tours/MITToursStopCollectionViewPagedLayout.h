#import <UIKit/UIKit.h>

@interface MITToursStopCollectionViewPagedLayout : UICollectionViewFlowLayout

// Our paging attempts to line up each cell to the given pagePosition (a point defined
// within the coordinate space of our bounds) according to the pageCellScrollPosition
// specified. For example, specifying a pagePosition (bounds.size.width/2, bounds.size.height/2)
// and a scroll position of UIScrollPositionTop | UIScrollPositionLeft will align the top
// left of each cell to the center of the collection view's bounds.
@property (nonatomic) CGPoint pagePosition;
@property (nonatomic) UICollectionViewScrollPosition pageCellScrollPosition;

@end
