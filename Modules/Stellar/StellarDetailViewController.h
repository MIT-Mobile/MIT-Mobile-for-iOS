#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "TabViewControl.h"
#import "MITModuleURL.h"


@class StellarDetailViewController;
@interface ClassInfoLoader : NSObject <ClassInfoLoadedDelegate>
{
	StellarDetailViewController *viewController;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;
@end

@interface MyStellarStatusDelegate : NSObject <JSONLoadedDelegate>
{
	StellarDetailViewController *viewController;
	BOOL status;
	StellarClass *stellarClass;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;

- (id) initWithClass: (StellarClass *)class status: (BOOL)newStatus viewController: (StellarDetailViewController *)controller;
@end

typedef enum {
	StellarNewsLoadingInProcess,
	StellarNewsLoadingSucceeded,
	StellarNewsLoadingFailed
} StellarNewsLoadingState;
	
@interface StellarDetailViewController : UITableViewController <TabViewControlDelegate> {
	ClassInfoLoader *currentClassInfoLoader;
	MyStellarStatusDelegate *myStellarStatusDelegate;
	
	StellarClass *stellarClass;
	
	NSArray *news;
	NSArray *instructors;
	NSArray *tas;
	NSArray *times;
	
	NSMutableArray *dataSources;
	
	UILabel *titleView;
	UILabel *termView;
	UIBarButtonItem *actionButton;
	UIButton *myStellarButton;
	
	TabViewControl *tabViewControl;
	NSString *currentTabName;
	NSMutableArray *currentTabNames; 

	BOOL refreshClass;
	StellarNewsLoadingState loadingState;
	
	MITModuleURL *url;
}

@property (nonatomic, retain) ClassInfoLoader *currentClassInfoLoader;
@property (nonatomic, retain) MyStellarStatusDelegate *myStellarStatusDelegate;

@property (nonatomic, retain) StellarClass *stellarClass;

@property (nonatomic, retain) NSArray *news;
@property (nonatomic, retain) NSArray *instructors;
@property (nonatomic, retain) NSArray *tas;
@property (nonatomic, retain) NSArray *times;

@property (nonatomic, assign) UILabel *titleView;
@property (nonatomic, assign) UILabel *termView;
@property (nonatomic, assign) UIButton *myStellarButton;

@property (nonatomic, retain) NSMutableArray *dataSources;

@property (nonatomic, assign) BOOL refreshClass;
@property (nonatomic, assign) StellarNewsLoadingState loadingState;

@property (readonly) MITModuleURL *url;

+ (StellarDetailViewController *) launchClass: (StellarClass *)stellarClass viewController: (UIViewController *)controller;

- (id) initWithClass: (StellarClass *)stellarClass;

- (void) loadClassInfo:(StellarClass *)class;

- (void) setCurrentTab: (NSString *)tabName;

- (void) openSite;

- (BOOL) dataLoadingComplete;

@end

@interface StellarDetailViewControllerComponent : NSObject {
	StellarDetailViewController *viewController;
}

@property (nonatomic, assign) StellarDetailViewController *viewController;
+ (StellarDetailViewControllerComponent *)viewController: (StellarDetailViewController *)controller;
@end

void makeCellWhite(UITableViewCell *cell);

@protocol StellarDetailTableViewDelegate <UITableViewDelegate, UITableViewDataSource>
- (CGFloat) heightOfTableView: (UITableView *)tableView;
@end
