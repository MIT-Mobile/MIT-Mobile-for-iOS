#import <UIKit/UIKit.h>

@class MITLibrariesSearchResultsViewController;
@class MITLibrariesItem;

@protocol MITLibrariesSearchResultsViewControllerDelegate <NSObject>

- (void)librariesSearchResultsViewController:(MITLibrariesSearchResultsViewController *)searchResultsViewController didSelectItem:(MITLibrariesItem *)item;

@end

@interface MITLibrariesSearchResultsViewController : UIViewController

@property (nonatomic, weak) id<MITLibrariesSearchResultsViewControllerDelegate> delegate;

- (void)search:(NSString *)searchTerm;

@end
