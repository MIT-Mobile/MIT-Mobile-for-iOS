#import <UIKit/UIKit.h>

@interface MITMobiusAdvancedSearchViewController : UITableViewController
@property (nonatomic,copy) NSString *searchText;

- (instancetype)initWithStyle:(UITableViewStyle)style;
- (instancetype)initWithSearchText:(NSString*)searchText;

@end
