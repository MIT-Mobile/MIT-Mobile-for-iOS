#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITLibrariesSearchResultsViewControllerState) {
    MITLibrariesSearchResultsViewControllerStateLoading,
    MITLibrariesSearchResultsViewControllerStateError,
    MITLibrariesSearchResultsViewControllerStateResults
};

@class MITLibrariesSearchResultsViewController, MITLibrariesWorldcatItem, MITLibrariesSearchController;

@protocol MITLibrariesSearchResultsViewControllerDelegate <NSObject>

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item;

@end

@interface MITLibrariesSearchResultsViewController : UIViewController

@property (nonatomic, assign) MITLibrariesSearchResultsViewControllerState state;
@property (nonatomic, weak) id<MITLibrariesSearchResultsViewControllerDelegate> delegate;
@property (nonatomic, strong) MITLibrariesSearchController *searchController;

- (void)search:(NSString *)searchTerm;
- (void)searchFinishedLoadingWithError:(NSError *)error;

@end
