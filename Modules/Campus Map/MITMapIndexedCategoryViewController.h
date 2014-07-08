#import <UIKit/UIKit.h>

@class MITMapCategory;

@interface MITMapIndexedCategoryViewController : UITableViewController

@property (nonatomic, strong) MITMapCategory *category;

- (instancetype)initWithCategory:(MITMapCategory *)category;

@end
