#import "MITNewsiPadViewController.h"
#import "MITNewsDataSource.h"

@class MITNewsStory;
@class MITNewsCategory;

@interface MITNewsiPadCategoryListViewController : UIViewController
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) MITNewsPresentationStyle presentationStyle;

@property (nonatomic, retain) MITNewsDataSource *dataSource;

@end