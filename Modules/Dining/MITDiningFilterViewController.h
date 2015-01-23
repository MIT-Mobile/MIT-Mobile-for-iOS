#import <UIKit/UIKit.h>

@protocol MITDiningFilterDelegate <NSObject>

- (void)applyFilters:(NSSet *)filters;

@end

@interface MITDiningFilterViewController : UITableViewController

@property (nonatomic) id<MITDiningFilterDelegate> delegate;

- (void)setSelectedFilters:(NSSet *)filters;
- (CGFloat)targetTableViewHeight;

@end
