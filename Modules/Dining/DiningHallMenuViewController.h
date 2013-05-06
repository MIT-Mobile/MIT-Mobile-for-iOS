#import <UIKit/UIKit.h>
#import "DiningMenuFilterViewController.h"

@interface DiningHallMenuViewController : UITableViewController <DiningMenuFilterDelegate>

@property (nonatomic, strong) NSDictionary * hallData;

@end
