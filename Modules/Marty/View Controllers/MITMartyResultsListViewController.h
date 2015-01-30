#import <UIKit/UIKit.h>

@class MITMapCategory, MITMapPlace;

@protocol MITMartyResultsListViewControllerDelegate;

@interface MITMartyResultsListViewController : UITableViewController

@property (nonatomic, copy) NSArray *places;
@property (nonatomic, weak) id <MITMartyResultsListViewControllerDelegate> delegate;
@property (nonatomic) BOOL hideDetailButton;

- (instancetype)initWithPlaces:(NSArray *)places;
- (void)setTitleWithSearchQuery:(NSString *)query;

@end

@protocol MITMartyResultsListViewControllerDelegate <NSObject>

@optional
- (void)resultsListViewController:(MITMartyResultsListViewController *)viewController didSelectPlace:(MITMapPlace *)place;

@end
