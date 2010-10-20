
#import <UIKit/UIKit.h>

@class CampusMapViewController;

@interface CategoriesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray* _categories;
	
	CampusMapViewController* _campusMapVC;
}

@property (nonatomic, retain) NSArray* categories;
@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@end
