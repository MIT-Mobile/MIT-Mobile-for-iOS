#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"
#import "MITMobiusRoomObject.h"
@interface MITMobiusRootPhoneViewController : UIViewController

@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,weak) IBOutlet UIView *helpTextView;
@property(nonatomic,weak) IBOutlet UIView *contentContainerView;
@property(nonatomic,weak) IBOutlet UIView *mapViewContainer;
@property(nonatomic,weak) IBOutlet UIView *tableViewContainer;

@end

@protocol MITMobiusRootViewRoomDataSource <NSObject>
- (NSInteger)numberOfRoomsForViewController:(UIViewController*)viewController;
- (MITMobiusRoomObject*)viewController:(UIViewController*)viewController roomAtIndex:(NSInteger)roomIndex;
- (NSInteger)viewController:(UIViewController*)viewController numberOfResourcesInRoomAtIndex:(NSInteger)roomIndex;
- (MITMobiusResource*)viewController:(UIViewController*)viewController resourceAtIndex:(NSInteger)resourceIndex inRoomAtIndex:(NSInteger)roomIndex;
@end