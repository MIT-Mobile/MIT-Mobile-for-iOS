#import "MITNewsStoriesViewController.h"

#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"

@interface MITNewsStoriesViewController ()

@end

@implementation MITNewsStoriesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad]; 
}

- (void)viewWillAppear:(BOOL)animated
{
    // Make sure the category is in the correct MOC!
    self.category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];

    [super viewWillAppear:animated];

    if (!self.managedObjectContext) {
        DDLogWarn(@"A managed object context was not before '%@' was added to the view hierarchy. Falling back to the main queue managed object context",self);
        self.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCategory:(MITNewsCategory *)category
{
    if (![_category isEqual:category]) {
        if (self.managedObjectContext) {
            _category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];
        } else {
            _category = category;
        }


        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        if (_category) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@",self.category];
        }

        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                         [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
        self.fetchRequest = fetchRequest;
    }
}

@end
