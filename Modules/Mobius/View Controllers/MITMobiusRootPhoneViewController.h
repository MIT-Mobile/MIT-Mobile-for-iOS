#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

@interface MITMobiusRootPhoneViewController : UIViewController

@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,weak) IBOutlet UIView *helpTextView;
@property(nonatomic,weak) IBOutlet UIView *contentContainerView;
@property(nonatomic,weak) IBOutlet UIView *mapViewContainer;
@property(nonatomic,weak) IBOutlet UIView *tableViewContainer;

@end

@protocol MITMobiusRoomDataSource <NSObject>

- (NSArray *)allRooms;
- (NSArray *)resourcesForRoom:(NSString *)roomNumber;
- (NSString *)roomNumberAtIndex:(NSInteger)index;
- (MITMobiusResource *)resourceInRoom:(NSString *)roomNumber withIndex:(NSInteger)index;
- (NSInteger)numberOfRooms;
- (NSInteger)numberOfResourcesForRoom:(NSString *)roomNumber;

@end