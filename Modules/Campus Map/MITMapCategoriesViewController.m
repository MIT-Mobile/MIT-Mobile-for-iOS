#import "MITMapCategoriesViewController.h"
#import "MITMapCategory.h"
#import "MITMapModelController.h"
#import "MITMapIndexedCategoryViewController.h"
#import "MITMapDefaultCategoryViewController.h"

static NSString * const kMITMapCategoryCellIdentifier = @"MITMapCategoryCell";

@interface MITMapCategoriesViewController ()

@property (nonatomic, copy) NSArray *categories;

@end

@implementation MITMapCategoriesViewController

@synthesize delegate = _delegate;

#pragma mark - Init

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        void (^fetchRequestBlock)(NSFetchRequest *) = ^(NSFetchRequest *fetchRequest) {
            if (fetchRequest) {
                NSError *fetchError = nil;
                self.categories = [[MITCoreDataController defaultController].mainQueueContext executeFetchRequest:fetchRequest error:&fetchError];
                [self.tableView reloadData];
            }
        };
        
        NSFetchRequest *fetchRequest = [[MITMapModelController sharedController] categories:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
            fetchRequestBlock(fetchRequest);
        }];
        fetchRequestBlock(fetchRequest);
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Categories";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Actions

- (void)doneButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapCategoryCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITMapCategoryCellIdentifier];
    }
    MITMapCategory *category = self.categories[indexPath.row];
    cell.textLabel.text = category.name;
    cell.imageView.image = [UIImage imageNamed:MITImageMapBrowseBuildings];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapCategory *category = self.categories[indexPath.row];
    UIViewController <MITMapPlaceSelector> *viewController;
    
    if ([category.children count] > 0) {
        viewController = [[MITMapIndexedCategoryViewController alloc] initWithCategory:category];
        if ([category.identifier isEqualToString:@"building_name"]) // This is the map place category
        {
            ((MITMapIndexedCategoryViewController *)viewController).shouldSortCategory = YES;
        }
    }
    else {
        viewController = [[MITMapDefaultCategoryViewController alloc] initWithCategory:category];
    }
    
    viewController.delegate = self.delegate;
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
