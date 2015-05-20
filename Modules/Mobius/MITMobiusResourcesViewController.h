#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MITMobiusDetailContainerViewController.h"
#import "MITTiledMapView.h"

@class MITMobiusResource;
@protocol MITMobiusResourcesDelegate;

@interface MITMobiusResourcesViewController : UIViewController
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) IBOutlet MITTiledMapView *mapView;
@property (nonatomic,weak) IBOutlet UITableView *tableView;

@property (nonatomic,weak) MITMobiusResource *selectedResource;
@property (nonatomic,copy) NSArray *selectedResources;

@property (nonatomic,strong) NSArray *resources;
@property (nonatomic,strong) UITapGestureRecognizer *mapFullScreenGesture;

@property (nonatomic) BOOL showsMap;
@property (nonatomic) BOOL showsMapFullScreen;
@property (nonatomic,getter=isLoading) BOOL loading;

@property (nonatomic,weak) id<MITMobiusResourcesDelegate> delegate;

- (void)setShowsMap:(BOOL)showsMap animated:(BOOL)animated;
- (void)setShowsMapFullScreen:(BOOL)showsMapFullScreen animated:(BOOL)animated;
- (void)setLoading:(BOOL)loading animated:(BOOL)animated;
- (void)reloadData;
@end

@protocol MITMobiusResourcesDelegate <NSObject>
@required
- (void)resourcesViewController:(MITMobiusResourcesViewController *)viewController didSelectResourcesWithIdentifiers:(NSArray*)resources;

@optional
- (void)resourceViewControllerWillShowFullScreenMap:(MITMobiusResourcesViewController*)viewController;
- (void)resourceViewControllerDidShowFullScreenMap:(MITMobiusResourcesViewController*)viewController;
- (void)resourceViewControllerWillHideFullScreenMap:(MITMobiusResourcesViewController*)viewController;
- (void)resourceViewControllerDidHideFullScreenMap:(MITMobiusResourcesViewController*)viewController;
@end