#import "MITLibrariesAvailabilityDetailViewController.h"
#import "MITLibrariesAvailability.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesAvailabilityDetailCell.h"

static NSInteger const kItemHeaderSection = 0;
static NSInteger const kAvailabilitiesSection = 1;

typedef NS_ENUM(NSInteger, MITAvailabilitiesDetailSection) {
    MITAvailabilitiesDetailSectionAll = 0,
    MITAvailabilitiesDetailSectionAvailable
};

static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kAvailabilityCellIdentifier = @"kAvailabilityCellIdentifier";

@interface MITLibrariesAvailabilityDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) NSArray *availableCopyAvailabilities;

@end

@implementation MITLibrariesAvailabilityDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Availability";
    
    [self registerCells];
    [self setupSegmentedControl];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.navigationController.toolbarHidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.navigationController.toolbarHidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setAvailabilitiesInLibrary:(NSArray *)availabilitiesInLibrary
{
    _availabilitiesInLibrary = availabilitiesInLibrary;
    
    NSMutableArray *newAvailableCopyAvailabilities = [NSMutableArray array];
    
    for (MITLibrariesAvailability *availability in availabilitiesInLibrary) {
        if (availability.available) {
            [newAvailableCopyAvailabilities addObject:availability];
        }
    }
    
    self.availableCopyAvailabilities = [NSArray arrayWithArray:newAvailableCopyAvailabilities];
}

- (void)registerCells
{
    UINib *itemHeaderNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.tableView registerNib:itemHeaderNib forCellReuseIdentifier:kItemHeaderCellIdentifier];
    
    UINib *availabilityNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesAvailabilityDetailCell class]) bundle:nil];
    [self.tableView registerNib:availabilityNib forCellReuseIdentifier:kAvailabilityCellIdentifier];
}

- (void)setupSegmentedControl
{
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Available"]];
    
    self.segmentedControl.selectedSegmentIndex = MITAvailabilitiesDetailSectionAll;
    [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.titleView = self.segmentedControl;
    } else {
        self.segmentedControl.bounds = CGRectMake(0, 0, self.navigationController.toolbar.bounds.size.width - 32, self.segmentedControl.bounds.size.height);
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.toolbarItems = @[flexibleSpace, [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl], flexibleSpace];
    }
    
    
}

- (void)segmentedControlChanged
{
    [self.tableView reloadData];
}

- (void)doneButtonPressed
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kItemHeaderSection: {
            return 1;
        }
        case kAvailabilitiesSection: {
            switch (self.segmentedControl.selectedSegmentIndex) {
                case MITAvailabilitiesDetailSectionAll: {
                    return self.availabilitiesInLibrary.count;
                }
                case MITAvailabilitiesDetailSectionAvailable: {
                    return self.availableCopyAvailabilities.count;
                }
                default: {
                    return 0;
                }
            }
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kItemHeaderSection: {
            MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
            [itemHeaderCell setContent:self.worldcatItem];
            return itemHeaderCell;
        }
        case kAvailabilitiesSection: {
            MITLibrariesAvailabilityDetailCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kAvailabilityCellIdentifier];
            
            switch (self.segmentedControl.selectedSegmentIndex) {
                case MITAvailabilitiesDetailSectionAll: {
                    [cell setContent:self.availabilitiesInLibrary[indexPath.row]];
                    break;
                }
                case MITAvailabilitiesDetailSectionAvailable: {
                    [cell setContent:self.availableCopyAvailabilities[indexPath.row]];
                    break;
                }
                default: {
                    return [UITableViewCell new];
                }
            }
            
            return cell;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kItemHeaderSection: {
            return [MITLibrariesWorldcatItemCell heightForContent:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
        }
        case kAvailabilitiesSection: {
            switch (self.segmentedControl.selectedSegmentIndex) {
                case MITAvailabilitiesDetailSectionAll: {
                    return [MITLibrariesAvailabilityDetailCell heightForContent:self.availabilitiesInLibrary[indexPath.row] tableViewWidth:self.tableView.bounds.size.width];
                }
                case MITAvailabilitiesDetailSectionAvailable: {
                    return [MITLibrariesAvailabilityDetailCell heightForContent:self.availableCopyAvailabilities[indexPath.row] tableViewWidth:self.tableView.bounds.size.width];
                }
                default: {
                    return 0;
                }
            }
        }
        default: {
            return 0;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kItemHeaderSection: {
            return nil;
        }
        case kAvailabilitiesSection: {
            return self.libraryName;
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kItemHeaderSection) {
        return 0.0001f;
    } else {
        return 35;
    }
}

@end
