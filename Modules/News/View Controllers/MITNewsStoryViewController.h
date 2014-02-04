#import <UIKit/UIKit.h>
#import "MITNewsStory.h"

@interface MITNewsStoryViewController : UIViewController
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) MITNewsStory *story;

@property (nonatomic,weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic,weak) IBOutlet UIWebView *bodyView;

@end
