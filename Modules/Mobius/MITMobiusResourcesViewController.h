#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MITMobiusDetailContainerViewController.h"

@class MITMobiusResource;
@protocol MITMobiusResourcesDataSource;
@protocol MITMobiusResourcesDelegate;

@interface MITMobiusResourcesViewController : UITableViewController <MITMobiusDetailPagingDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) MITMobiusResource *selectedResource;
@property (nonatomic,strong) NSArray *resources;

@property (nonatomic,readonly) BOOL showsMap;
@property (nonatomic,readonly) BOOL showsMapFullScreen;
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