#import <UIKit/UIKit.h>

extern NSString * const kMITMapRecentSearchCellIdentifier;

@protocol MITMapRecentsTableViewControllerDelegate;

@class MITMapPlace;
@class MITMapCategory;

@interface MITMapRecentsTableViewController : UITableViewController

@property (nonatomic, weak) id<MITMapRecentsTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *recentSearchItems;
@property (nonatomic) BOOL showsTitleHeader;

- (void)showTitleHeaderIfNecessary;

@end

@protocol MITMapRecentsTableViewControllerDelegate <NSObject>

- (void)typeAheadViewController:(MITMapRecentsTableViewController *)recentsViewController didSelectRecentQuery:(NSString *)recentQuery;
- (void)typeAheadViewController:(MITMapRecentsTableViewController *)recentsViewController didSelectPlace:(MITMapPlace *)place;
- (void)typeAheadViewController:(MITMapRecentsTableViewController *)recentsViewController didSelectCategory:(MITMapCategory *)category;

@end