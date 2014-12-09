#import <UIKit/UIKit.h>

@protocol MITLibrariesRecentSearchesDelegate <NSObject>

- (void)recentSearchesDidSelectSearchTerm:(NSString *)searchTerm;

@end

@interface MITLibrariesRecentSearchesViewController : UITableViewController

@property (nonatomic, strong) id<MITLibrariesRecentSearchesDelegate> delegate;

@end
