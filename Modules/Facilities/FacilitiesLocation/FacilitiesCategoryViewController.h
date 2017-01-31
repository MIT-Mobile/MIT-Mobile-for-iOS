#import <UIKit/UIKit.h>

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;
@class FacilitiesLocationSearch;

@interface FacilitiesCategoryViewController : UIViewController
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) MITLoadingActivityView* loadingView;

- (NSArray*)dataForMainTableView;
- (NSArray*)resultsForSearchString:(NSString*)searchText;

- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (void)configureSearchCell:(HighlightTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
