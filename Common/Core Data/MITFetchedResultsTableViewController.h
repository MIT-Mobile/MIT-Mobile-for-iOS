#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MITFetchedResultsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSFetchRequest *fetchRequest;
@property (nonatomic,getter = shouldUpdateTableOnResultsChange) BOOL updateTableOnResultsChange;

- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest;
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end
