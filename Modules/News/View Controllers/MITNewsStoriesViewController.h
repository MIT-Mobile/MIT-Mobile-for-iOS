#import <UIKit/UIKit.h>
#import "MITFetchedResultsTableViewController.h"

@class MITNewsCategory;

@interface MITNewsStoriesViewController : UITableViewController
@property (nonatomic,readonly) MITNewsCategory *category;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

- (void)setCategoryWithObjectID:(NSManagedObjectID*)objectID;
@end
