#import <UIKit/UIKit.h>
#import "MITMapPlaceSelector.h"

@interface MITMapDefaultCategoryViewController : UITableViewController <MITMapPlaceSelector>

@property (nonatomic, strong) MITMapCategory *category;

- (instancetype)initWithCategory:(MITMapCategory *)category;

@end
