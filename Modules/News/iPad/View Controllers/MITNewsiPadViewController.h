#import <UIKit/UIKit.h>
#import "MITNewsStoryDetailController.h"

@interface MITNewsiPadViewController : UIViewController

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (MITNewsStory*)newsDetailController:(MITNewsStoryDetailController*)storyDetailController storyAfterStory:(MITNewsStory*)story;
@end
