#import <UIKit/UIKit.h>

@interface MITNewsRecentSearchController : UIViewController

@property (nonatomic, readonly) UIActionSheet *confirmSheet;
- (void)addRecentSearchItem:(NSString *)searchTerm;
- (void)filterResultsUsingString:(NSString *)filterString;

@end
