#import <UIKit/UIKit.h>

@class MITLibrariesSearchResultsViewController, MITLibrariesWorldcatItem, MITLibrariesSearchController;

@protocol MITLibrariesSearchResultsViewControllerDelegate <NSObject>

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item;

@end

@interface MITLibrariesSearchResultsViewController : UIViewController

@property (nonatomic, weak) id<MITLibrariesSearchResultsViewControllerDelegate> delegate;
@property (nonatomic, strong) MITLibrariesSearchController *searchController;

- (void)search:(NSString *)searchTerm;

@end
