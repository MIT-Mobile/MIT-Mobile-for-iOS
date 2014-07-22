#import <UIKit/UIKit.h>
#import "MITMapPlaceSelector.h"

extern NSString * const kMITMapRecentSearchCellIdentifier;

@class MITMapPlace;
@class MITMapCategory;

@interface MITMapRecentsTableViewController : UITableViewController <MITMapPlaceSelector>

@property (nonatomic, strong) NSArray *recentSearchItems;
@property (nonatomic) BOOL showsTitleHeader;
@property (nonatomic) BOOL showsNoRecentsMessage;

- (void)showTitleHeaderIfNecessary;

@end
