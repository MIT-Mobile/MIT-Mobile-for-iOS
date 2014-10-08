#import <UIKit/UIKit.h>

@class MITMapCategory, MITMapPlace;

@protocol MITMapResultsListViewControllerDelegate;

@interface MITMapResultsListViewController : UITableViewController

@property (nonatomic, copy) NSArray *places;
@property (nonatomic, weak) id <MITMapResultsListViewControllerDelegate> delegate;
@property (nonatomic) BOOL hideDetailButton;

- (instancetype)initWithPlaces:(NSArray *)places;
- (void)setTitleWithSearchQuery:(NSString *)query;

@end

@protocol MITMapResultsListViewControllerDelegate <NSObject>

@optional
- (void)resultsListViewController:(MITMapResultsListViewController *)viewController didSelectPlace:(MITMapPlace *)place;

@end
