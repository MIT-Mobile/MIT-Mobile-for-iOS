#import "MITMapCategoriesViewController.h"
#import "MITMapCategory.h"
#import "MITMapModelController.h"
#import "MITMapIndexedCategoryViewController.h"

static NSString * const kMITMapCategoryCellIdentifier = @"MITMapCategoryCell";

@interface MITMapCategoriesViewController ()

@property (nonatomic, copy) NSArray *categories;

@end

@implementation MITMapCategoriesViewController

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
    [self setupDoneBarButtonItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupDoneBarButtonItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
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
    cell.imageView.image = [UIImage imageNamed:@"map/map_browse_building" /*category.iconName*/];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapCategory *category = self.categories[indexPath.row];
    if ([category.children count] > 0) {
        MITMapIndexedCategoryViewController *viewController = [[MITMapIndexedCategoryViewController alloc] initWithCategory:category];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    // TODO: push category view controller
}

@end
