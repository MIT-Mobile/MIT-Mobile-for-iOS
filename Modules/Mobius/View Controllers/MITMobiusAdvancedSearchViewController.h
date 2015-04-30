#import <UIKit/UIKit.h>

@class MITMobiusRecentSearchQuery;
@protocol MITMobiusAdvancedSearchDelegate;

@interface MITMobiusAdvancedSearchViewController : UITableViewController
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) MITMobiusRecentSearchQuery *query;
@property (nonatomic,weak) id<MITMobiusAdvancedSearchDelegate> delegate;

- (instancetype)init;
- (instancetype)initWithString:(NSString*)queryString;
- (instancetype)initWithQuery:(MITMobiusRecentSearchQuery*)query;

@end

@protocol MITMobiusAdvancedSearchDelegate <NSObject>
- (void)advancedSearchViewControllerDidCancelSearch:(MITMobiusAdvancedSearchViewController*)viewController;
- (void)didDismissAdvancedSearchViewController:(MITMobiusAdvancedSearchViewController*)viewController;
@end