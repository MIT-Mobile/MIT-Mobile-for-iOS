#import "MITDiningFilterViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITDiningMenuItem.h"
#import "UIImage+PDF.h"

static NSString *const kMITDiningFilterCell = @"kMITDiningFilterCell";

@interface MITDiningFilterViewController ()

@property (nonatomic, strong) NSMutableSet *mutableSelectedFilters;
@property (nonatomic, strong) NSArray *allFilters;

@end

@implementation MITDiningFilterViewController

- (void)setSelectedFilters:(NSSet *)filters
{
    self.mutableSelectedFilters = [filters mutableCopy];
}

- (void) commitChanges:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(applyFilters:)]) {
        [self.delegate applyFilters:self.mutableSelectedFilters];
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
    
    self.allFilters = [MITDiningMenuItem allDietaryFlagsKeys];
    
    if (!self.mutableSelectedFilters) {
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITDiningFilterCell];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITDiningFilterCell];
    }
    
    NSString *filterKey = self.allFilters[indexPath.row];
    UIImage *filterImage = [UIImage imageWithPDFNamed:[MITDiningMenuItem pdfNameForDietaryFlag:filterKey] fitSize:CGSizeMake(24, 24)];
    
    if ([self.mutableSelectedFilters containsObject:filterKey]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [MITDiningMenuItem displayNameForDietaryFlag:filterKey];// filterItem.displayName;
    cell.imageView.image = filterImage;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
   
    NSString *filterKey = self.allFilters[indexPath.row];
    if ([self.mutableSelectedFilters containsObject:filterKey]) {
        [self.mutableSelectedFilters removeObject:filterKey];
    } else {
        [self.mutableSelectedFilters addObject:filterKey];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
