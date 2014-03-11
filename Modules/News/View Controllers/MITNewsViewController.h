#import <UIKit/UIKit.h>

@interface MITNewsViewController : UITableViewController
@property (nonatomic,getter = isShowingFeaturedStories) BOOL showFeaturedStories;
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
@end
