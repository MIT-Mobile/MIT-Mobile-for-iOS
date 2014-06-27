#import <UIKit/UIKit.h>

@protocol MITNewsSearchDelegate;

@interface MITNewsSearchController : UIViewController

- (NSArray *)showSearchFieldFromItems:(NSArray *)navigationBarItems;
@property (nonatomic, weak) id<MITNewsSearchDelegate> delegate;

@end

@protocol MITNewsSearchDelegate <NSObject>

- (void)hideSearchField;

@end