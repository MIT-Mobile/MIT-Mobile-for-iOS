#import <UIKit/UIKit.h>

@protocol DiningMenuFilterDelegate <NSObject>

- (void) applyFilters:(NSArray *) filters;

@end

@interface DiningMenuFilterViewController : UITableViewController

@property (nonatomic) id<DiningMenuFilterDelegate> delegate;

- (void) setFilters:(NSArray *)filters;

@end
