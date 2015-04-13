#import <UIKit/UIKit.h>

@class MITMobiusRecentSearchQuery;

@interface MITMobiusAdvancedSearchViewController : UITableViewController
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) MITMobiusRecentSearchQuery *query;

- (instancetype)init;
- (instancetype)initWithQuery:(MITMobiusRecentSearchQuery*)query;

@end
