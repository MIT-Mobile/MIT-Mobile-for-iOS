#import "DiningMenuFilterViewController.h"
#import "DiningHallMenuViewController.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"
#import "UIImage+PDF.h"
#import "UIKit+MITAdditions.h"

@interface DiningMenuFilterViewController ()

@property (nonatomic, strong) NSMutableSet * selectedFilters;
@property (nonatomic, strong) NSArray * allFilters;

@end

@implementation DiningMenuFilterViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void) setFilters:(NSArray *)filters
{
    self.selectedFilters = [filters mutableCopy];
}

- (void) commitChanges:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(applyFilters:)]) {
        [self.delegate applyFilters:self.selectedFilters];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor colorWithHexString:@"#e1e3e8"];
    }
    
    self.title = @"Filters";
    self.tableView.rowHeight = 44;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(commitChanges:)];
    
    NSSortDescriptor *alphabetical = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO];
    self.allFilters = [[CoreDataManager coreDataManager] objectsForEntity:@"DiningDietaryFlag" matchingPredicate:nil sortDescriptors:@[alphabetical]];

    if (!self.selectedFilters) {
        self.selectedFilters = [[NSMutableSet alloc] init];
    }
    
    [self addHeaderToTableView];
}

- (void)addHeaderToTableView
{
    UILabel *headerLabel = [UILabel new];
    headerLabel.text = @"Select options to be viewed.";
    headerLabel.bounds = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 40);
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = [UIColor darkTextColor];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont systemFontOfSize:15.0];
    self.tableView.tableHeaderView = headerLabel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL) shouldAutorotate
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allFilters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"FilterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    DiningDietaryFlag *filterItem = self.allFilters[indexPath.row];
    UIImage *filterImage = [UIImage imageWithPDFNamed:filterItem.pdfPath fitSize:CGSizeMake(24, 24)];
    
    
    if ([self.selectedFilters containsObject:filterItem]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = filterItem.displayName;
    cell.imageView.image = filterImage;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DiningDietaryFlag *filterItem = self.allFilters[indexPath.row];
    if ([self.selectedFilters containsObject:filterItem]) {
        [self.selectedFilters removeObject:filterItem];
    } else {
        [self.selectedFilters addObject:filterItem];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
