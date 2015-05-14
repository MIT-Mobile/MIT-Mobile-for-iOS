#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MITMobiusDetailContainerViewController.h"

@class MITTiledMapView;
@class MITMobiusResource;
@protocol MITMobiusResourcesDataSource;
@protocol MITMobiusResourcesDelegate;

@interface MITMobiusResourcesViewController : UIViewController <MITMobiusDetailPagingDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) IBOutlet MITTiledMapView *mapView;
@property (nonatomic,weak) IBOutlet UITableView *tableView;

@property (nonatomic,weak) MITMobiusResource *selectedResource;
@property (nonatomic,strong) NSArray *resources;

@property (nonatomic) BOOL showsMap;
@property (nonatomic) BOOL showsMapFullScreen;
@property (nonatomic,weak) id<MITMobiusResourcesDelegate> delegate;

- (void)reloadData;
@end

@protocol MITMobiusResourcesDelegate <NSObject>
@required
- (void)resourcesViewController:(MITMobiusResourcesViewController*)viewController didSelectResourceWithIdentifier:(NSString*)identifier;

@optional
- (BOOL)resourcesViewControllerShowsMapView:(MITMobiusResourcesViewController*)viewController;
- (BOOL)resourcesViewControllerShowsMapFullScreen:(MITMobiusResourcesViewController*)viewController;
@end