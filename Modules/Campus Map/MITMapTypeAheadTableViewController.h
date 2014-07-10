#import <UIKit/UIKit.h>

@class MITMapPlace;
@class MITMapCategory;

@protocol MITMapTypeAheadTableViewControllerDelegate;

@interface MITMapTypeAheadTableViewController : UITableViewController

@property (nonatomic, weak) id<MITMapTypeAheadTableViewControllerDelegate> delegate;
@property (nonatomic) BOOL showsTitleHeader;

- (void)updateResultsWithSearchTerm:(NSString *)searchTerm;

@end

@protocol MITMapTypeAheadTableViewControllerDelegate <NSObject>

- (void)typeAheadViewController:(MITMapTypeAheadTableViewController *)typeAheadViewController didSelectRecentQuery:(NSString *)recentQuery;
- (void)typeAheadViewController:(MITMapTypeAheadTableViewController *)typeAheadViewController didSelectPlace:(MITMapPlace *)place;
- (void)typeAheadViewController:(MITMapTypeAheadTableViewController *)typeAheadViewController didSelectCategory:(MITMapCategory *)category;

@end