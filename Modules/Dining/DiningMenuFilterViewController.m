//
//  DiningMenuFilterViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/11/13.
//
//

#import "DiningMenuFilterViewController.h"
#import "UIImage+PDF.h"

@interface DiningMenuFilterViewController ()

@property (nonatomic, strong) NSMutableArray * selectedIndexPaths;

@end

@implementation DiningMenuFilterViewController

- (NSArray *) debugData
{
    return @[@{@"icon": @"farm_to_fork.pdf",    @"title" : @"Farm to Fork"},
             @{@"icon": @"well_being.pdf",      @"title" : @"For Your Well-Being"},
             @{@"icon": @"gluten_free.pdf",     @"title" : @"Gluten Free"},
             @{@"icon": @"halal.pdf",           @"title" : @"Halal"},
             @{@"icon": @"humane.pdf",          @"title" : @"Humane"},
             @{@"icon": @"in_balance.pdf",      @"title" : @"In Balance"},
             @{@"icon": @"kosher.pdf",          @"title" : @"Kosher"},
             @{@"icon": @"organic.pdf",         @"title" : @"Organic"},
             @{@"icon": @"seafood_watch.pdf",   @"title" : @"Seafood Watch"},
             @{@"icon": @"vegan.pdf",           @"title" : @"Vegan"},
             @{@"icon": @"vegetarian.pdf",      @"title" : @"Vegetarian"}];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

-(void) cancelPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) commitChanges:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
    NSLog(@"Here are the selected filters :: %@", self.selectedIndexPaths);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 44;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(commitChanges:)];

    if (!self.selectedIndexPaths) {
        self.selectedIndexPaths = [[NSMutableArray alloc] init];
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
    NSString *resourcePath = [NSString stringWithFormat:@"dining/%@", filterItem[@"icon"]];
    UIImage *filterImage = [UIImage imageWithPDFNamed:resourcePath fitSize:CGSizeMake(20, 20)];
    
    
    if ([self.selectedIndexPaths containsObject:indexPath]) {
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
    if ([self.selectedIndexPaths containsObject:indexPath]) {
        [self.selectedIndexPaths removeObject:indexPath];
    } else {
        [self.selectedIndexPaths addObject:indexPath];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
