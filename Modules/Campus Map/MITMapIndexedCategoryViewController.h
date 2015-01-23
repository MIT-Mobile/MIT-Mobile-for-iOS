#import <UIKit/UIKit.h>
#import "MITMapPlaceSelector.h"

@class MITMapCategory;

@interface MITMapIndexedCategoryViewController : UITableViewController <MITMapPlaceSelector>

@property (nonatomic, strong) MITMapCategory *category;
@property (nonatomic) BOOL shouldSortCategory;

- (instancetype)initWithCategory:(MITMapCategory *)category;

@end
