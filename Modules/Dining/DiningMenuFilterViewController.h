#import <UIKit/UIKit.h>

@protocol DiningMenuFilterDelegate <NSObject>

- (void) applyFilters:(NSSet *) filters;

@end

@interface DiningMenuFilterViewController : UITableViewController

@property (nonatomic) id<DiningMenuFilterDelegate> delegate;

- (void) setFilters:(NSSet *)filters;

@end
