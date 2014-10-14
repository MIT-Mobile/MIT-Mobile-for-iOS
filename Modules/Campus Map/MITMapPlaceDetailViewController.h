#import <UIKit/UIKit.h>

@class MITMapPlace;

@interface MITMapPlaceDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITMapPlace *place;

@end
