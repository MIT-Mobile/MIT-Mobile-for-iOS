#import <UIKit/UIKit.h>

@interface MITMartyRootPhoneViewController : UIViewController
@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property(nonatomic,weak) IBOutlet UIView *helpTextView;
@property(nonatomic,weak) IBOutlet UIView *contentContainerView;
@property(nonatomic,weak) IBOutlet UIView *mapViewContainer;
@property(nonatomic,weak) IBOutlet UIView *tableViewContainer;
@end
