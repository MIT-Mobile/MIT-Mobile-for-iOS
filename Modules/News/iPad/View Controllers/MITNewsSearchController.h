#import <UIKit/UIKit.h>

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController

- (UISearchBar *)returnSearchBar;
@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end