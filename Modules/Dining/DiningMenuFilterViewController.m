#import "DiningMenuFilterViewController.h"
#import "DiningHallMenuViewController.h"
#import "UIImage+PDF.h"

@interface DiningMenuFilterViewController ()

@property (nonatomic, strong) NSMutableSet * selectedFilters;

@end

@implementation DiningMenuFilterViewController

- (NSArray *) debugData
{
    return @[@{@"id": @"farm_to_fork",    @"title" : @"Farm to Fork"},
             @{@"id": @"well_being",      @"title" : @"For Your Well-Being"},
             @{@"id": @"gluten_free",     @"title" : @"Gluten Free"},
             @{@"id": @"halal",           @"title" : @"Halal"},
             @{@"id": @"humane",          @"title" : @"Humane"},
             @{@"id": @"in_balance",      @"title" : @"In Balance"},
             @{@"id": @"kosher",          @"title" : @"Kosher"},
             @{@"id": @"organic",         @"title" : @"Organic"},
             @{@"id": @"seafood_watch",   @"title" : @"Seafood Watch"},
             @{@"id": @"vegan",           @"title" : @"Vegan"},
             @{@"id": @"vegetarian",      @"title" : @"Vegetarian"}];
}

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

-(void) cancelPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) commitChanges:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(applyFilters:)]) {
        [self.delegate applyFilters:self.selectedFilters];
    }
    
    [self dismissModalViewControllerAnimated:YES];
    NSLog(@"Here are the selected filters :: %@", self.selectedFilters);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Filters";
    self.tableView.rowHeight = 44;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(commitChanges:)];

    if (!self.selectedFilters) {
        self.selectedFilters = [[NSMutableSet alloc] init];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self debugData] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"FilterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *filterItem = [[self debugData] objectAtIndex:indexPath.row];
    NSString *resourcePath = [NSString stringWithFormat:@"dining/%@.pdf", filterItem[@"id"]];
    UIImage *filterImage = [UIImage imageWithPDFNamed:resourcePath fitSize:CGSizeMake(24, 24)];
    
    
    if ([self.selectedFilters containsObject:filterItem[@"id"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = filterItem[@"title"];
    cell.imageView.image = filterImage;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *filterItem = [[self debugData] objectAtIndex:indexPath.row];
    if ([self.selectedFilters containsObject:filterItem[@"id"]]) {
        [self.selectedFilters removeObject:filterItem[@"id"]];
    } else {
        [self.selectedFilters addObject:filterItem[@"id"]];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
