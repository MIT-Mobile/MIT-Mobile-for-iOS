#import <UIKit/UIKit.h>

@interface MITNewsViewController : UITableViewController
@property (nonatomic) BOOL showFeaturedStoriesSection;
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender;
@end
