#import <UIKit/UIKit.h>
#import "MITMapPlaceSelector.h"

@class MITMapPlace;
@class MITMapCategory;

@interface MITMartyRecentSearchController : UITableViewController <MITMapPlaceSelector>
@property(nonatomic,weak) id<MITMapPlaceSelectionDelegate> delegate;
@property (nonatomic, readonly) UIActionSheet *confirmSheet;

- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;

@end