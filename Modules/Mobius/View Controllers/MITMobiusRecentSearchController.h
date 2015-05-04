#import <UIKit/UIKit.h>
#import "MITMapPlaceSelector.h"

@class MITMapPlace;
@class MITMapCategory;

@interface MITMobiusRecentSearchController : UITableViewController <MITMapPlaceSelector>
@property (nonatomic,weak) id<MITMapPlaceSelectionDelegate> delegate;
@property (nonatomic,weak,readonly) UIActionSheet *confirmSheet;
@property (nonatomic,readonly,strong) UIBarButtonItem *clearButtonItem;

- (void)filterResultsUsingString:(NSString *)filterString;

@end