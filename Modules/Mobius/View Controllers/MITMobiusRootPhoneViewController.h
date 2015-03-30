#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@interface MITMobiusRootPhoneViewController : UIViewController

@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,weak) IBOutlet UIView *helpTextView;
@property(nonatomic,weak) IBOutlet UIView *contentContainerView;
@property(nonatomic,weak) IBOutlet UIView *mapViewContainer;
@property(nonatomic,weak) IBOutlet UIView *tableViewContainer;

@end

@protocol MITMobiusRootViewRoomDataSource <NSObject>

- (NSArray *)allRoomsInViewController:(UIViewController *)viewController;
- (NSArray *)viewController:(UIViewController *)viewController resourcesForRoom:(NSString *)roomNumber;
- (NSString *)viewController:(UIViewController *)viewController roomNumberAtIndex:(NSInteger)index;
- (MITMobiusResource *)viewController:(UIViewController *)viewController resourceInRoom:(NSString *)roomNumber withIndex:(NSInteger)index;
- (NSInteger)numberOfRoomsInViewController:(UIViewController *)viewController;
- (NSInteger)viewController:(UIViewController *)viewController numberOfResourcesForRoom:(NSString *)roomNumber;

@end