#import "MITDiningFilterViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITDiningMenuItem.h"
#import "UIImage+PDF.h"

static NSString *const kMITDiningFilterCell = @"kMITDiningFilterCell";

static CGFloat const kMITDiningFilterHeaderHeight = 40.0;

@interface MITDiningFilterViewController ()

@property (nonatomic, strong) NSMutableSet *mutableSelectedFilters;
@property (nonatomic, strong) NSArray *allFilters;

@end

@implementation MITDiningFilterViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.allFilters = [MITDiningMenuItem allDietaryFlagsKeys];
}

- (void)setSelectedFilters:(NSSet *)filters
{
    self.mutableSelectedFilters = [filters mutableCopy];
}

- (void)commitChanges:(id)sender
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
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(commitChanges:)];
    }
    
    if (!self.mutableSelectedFilters) {
        self.selectedFilters = [[NSMutableSet alloc] init];
    }
    
    [self addHeaderToTableView];
}

- (void)addHeaderToTableView
{
    UILabel *headerLabel = [UILabel new];
    headerLabel.text = @"Select options to be viewed.";
    headerLabel.bounds = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kMITDiningFilterHeaderHeight);
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = [UIColor mit_greyTextColor];
    headerLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
    headerLabel.font = [UIFont systemFontOfSize:14.0];
    
    UIView *separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                    kMITDiningFilterHeaderHeight -1,
                                                                    headerLabel.bounds.size.width,
                                                                    1)];
    separatorBar.backgroundColor = [UIColor mit_cellSeparatorColor];
    [headerLabel addSubview:separatorBar];
    
    self.tableView.tableHeaderView = headerLabel;
}

- (CGFloat)targetTableViewHeight
{
    CGFloat tableHeight= 0.0;
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.tableView]; section++) {
        for (NSInteger row = 0; row < [self tableView:self.tableView numberOfRowsInSection:section]; row++) {
            tableHeight += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    tableHeight += kMITDiningFilterHeaderHeight;
    
    return tableHeight;
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
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if ([self.delegate respondsToSelector:@selector(applyFilters:)]) {
            [self.delegate applyFilters:self.mutableSelectedFilters];
        }
    }
}

@end
