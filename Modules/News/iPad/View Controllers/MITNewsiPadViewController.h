#import <UIKit/UIKit.h>

@interface MITNewsiPadViewController : UIViewController

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
