#import <Foundation/Foundation.h>

@interface WorldCatSearchController : NSObject  <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,weak) UINavigationController *navigationController;

- (void)doSearch:(NSString *)searchTerms;
- (void)clearSearch;
@end
