#import <UIKit/UIKit.h>

@class MITMapCategory, MITMartyResource;

@protocol MITMartyResultsListViewControllerDelegate;

@interface MITMartyResultsListViewController : UITableViewController

@property (nonatomic, copy) NSArray *resources;
@property (nonatomic, weak) id <MITMartyResultsListViewControllerDelegate> delegate;
@property (nonatomic) BOOL hideDetailButton;

- (instancetype)initWithResources:(NSArray *)resources;
- (void)setTitleWithSearchQuery:(NSString *)query;

@end

@protocol MITMartyResultsListViewControllerDelegate <NSObject>

@optional
- (void)resultsListViewController:(MITMartyResultsListViewController *)viewController didSelectResource:(MITMartyResource *)resource;

@end
