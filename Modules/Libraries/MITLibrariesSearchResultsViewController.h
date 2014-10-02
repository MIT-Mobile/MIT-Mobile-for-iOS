#import <UIKit/UIKit.h>

@class MITLibrariesSearchResultsViewController;
@class MITLibrariesWorldcatItem;

@protocol MITLibrariesSearchResultsViewControllerDelegate <NSObject>

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesWorldcatItem *)item;

@end

@interface MITLibrariesSearchResultsViewController : UIViewController

@property (nonatomic, weak) id<MITLibrariesSearchResultsViewControllerDelegate> delegate;

- (void)search:(NSString *)searchTerm;

@end