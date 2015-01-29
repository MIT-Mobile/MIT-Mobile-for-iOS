#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MITFetchedResultsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSFetchRequest *fetchRequest;

@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,getter = shouldUpdateTableOnResultsChange) BOOL updateTableOnResultsChange;

- (instancetype)init;
- (instancetype)initWithFetchRequest:(NSFetchRequest*)fetchRequest;
@end
