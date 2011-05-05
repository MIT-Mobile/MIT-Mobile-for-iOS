#import <CoreLocation/CoreLocation.h>

#import "FacilitiesLocationViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesUserLocation.h"
#import "MITLogging.h"
#import "MITLoadingActivityView.h"

@interface FacilitiesLocationViewController ()
@property (nonatomic,retain) NSArray* cachedData;
@property (nonatomic,retain) NSArray* filteredData;
@property (nonatomic) FacilitiesDisplayType viewMode;
@end

@implementation FacilitiesLocationViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;

@synthesize locationData = _locationData;
@synthesize filteredData = _filteredData;
@synthesize cachedData = _cachedData;
@synthesize viewMode = _viewMode;
@dynamic filterPredicate;

- (id)initWithViewMode:(FacilitiesDisplayType)viewMode
{
    self = [super initWithNibName:@"FacilitiesLocationViewController"
                           bundle:nil];
    if (self) {
        self.title = @"Where is it?";
        self.viewMode = viewMode;
        self.filterPredicate = [NSPredicate predicateWithFormat:@"(parent == nil) AND ((locations.@count > 0) OR (subcategories.@count > 0))"];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithViewMode:FacilitiesDisplayCategory];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: @"Back"
                                                                   style: UIBarButtonItemStyleBordered
                                                                  target: nil
                                                                  action: nil];
    self.navigationItem.backBarButtonItem = [backButton autorelease];
    
    self.tableView.hidden = YES;
    self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
    [self.view insertSubview:self.loadingView
                aboveSubview:self.tableView];
    self.locationData = [FacilitiesLocationData sharedData];
    [[FacilitiesLocationData sharedData] notifyOnDataAvailable: ^{
        [self.loadingView removeFromSuperview];
        self.tableView.hidden = NO;
        [self.tableView reloadInputViews];
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark Dynamic Setters/Getters
- (void)setFilterPredicate:(NSPredicate *)filterPredicate {
    self.cachedData = nil;
    [_filterPredicate release];
    _filterPredicate = [filterPredicate retain];
}

- (NSPredicate*)filterPredicate {
    return _filterPredicate;
}


#pragma mark -
#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocationViewController *tmpView = nil;
    FacilitiesCategory *category = nil;
    
    UIViewController *nextViewController = nil;
    
    switch (self.viewMode) {
        case FacilitiesDisplayCategory:
            if (indexPath.section == 0) {
                nextViewController = [[[FacilitiesUserLocation alloc] init] autorelease];
            } else {
                category = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
                
                if ([category.subcategories count] > 0) {
                    tmpView = [[[FacilitiesLocationViewController alloc] initWithViewMode:FacilitiesDisplaySubcategory] autorelease];
                    tmpView.filterPredicate = [NSPredicate predicateWithFormat:@"(parent != nil) AND (parent.uid == %@)",category.uid];
                } else {
                    tmpView = [[[FacilitiesLocationViewController alloc] initWithViewMode:FacilitiesDisplayLocation] autorelease];
                    tmpView.filterPredicate = [NSPredicate predicateWithFormat:@"ANY categories.uid == %@",category.uid];
                }
                
                nextViewController = tmpView;
            }
            break;
        case FacilitiesDisplaySubcategory:
            category = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
            tmpView = [[[FacilitiesLocationViewController alloc] initWithViewMode:FacilitiesDisplayLocation] autorelease];
            tmpView.filterPredicate = [NSPredicate predicateWithFormat:@"ANY categories.uid == %@",category.uid];
            nextViewController = tmpView;
            break;
        case FacilitiesDisplayLocation:
            break;
        case FacilitiesDisplayRoom:
            break;
    }
    
    if (nextViewController) {
        [self.navigationController pushViewController:nextViewController
                                             animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:(nextViewController == nil)];
}


#pragma mark -
#pragma mark UITableViewDataSource Methods
- (void)cacheDisplayData {
    NSArray *data = nil;
    
    if (self.cachedData == nil) {
        switch (self.viewMode) {
            case FacilitiesDisplayCategory:
                data = [self.locationData categoriesWithPredicate:self.filterPredicate];
                self.cachedData = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
                    FacilitiesCategory *c1 = (FacilitiesCategory*)obj1;
                    FacilitiesCategory *c2 = (FacilitiesCategory*)obj2;
                    
                    return [c1.name compare:c2.name];
                }];
                break;
                
            case FacilitiesDisplaySubcategory:
                data = [self.locationData categoriesWithPredicate:self.filterPredicate];
                
                self.cachedData = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
                    FacilitiesCategory *c1 = (FacilitiesCategory*)obj1;
                    FacilitiesCategory *c2 = (FacilitiesCategory*)obj2;
                    
                    return [c1.name compare:c2.name];
                }];
                break;
                
            case FacilitiesDisplayLocation:
                data = [self.locationData locationsWithPredicate:self.filterPredicate];

                self.cachedData = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
                    FacilitiesLocation *l1 = (FacilitiesLocation*)obj1;
                    FacilitiesLocation *l2 = (FacilitiesLocation*)obj2;
                    
                    return [l1.name compare:l2.name];
                }];
                break;
            case FacilitiesDisplayRoom:
                self.cachedData = [NSArray array];
                break;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.viewMode == FacilitiesDisplayCategory) {
        return ([CLLocationManager locationServicesEnabled] ? 2 : 1);
    } else if (self.viewMode == FacilitiesDisplayRoom) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self cacheDisplayData];
    
    switch (self.viewMode) {
        case FacilitiesDisplayCategory:
            return ((section == 0) && [CLLocationManager locationServicesEnabled]) ? 1 : [self.cachedData count];
        case FacilitiesDisplayRoom:
            return (section == 0) ? 1 : [self.cachedData count];
        default:
            return [self.cachedData count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"facilitiesCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self cacheDisplayData];
    
    if (self.viewMode == FacilitiesDisplayCategory) {
        if ((indexPath.section == 0) && [CLLocationManager locationServicesEnabled]) {
            cell.textLabel.text = @"Use My Location";
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            FacilitiesCategory *category = [self.cachedData objectAtIndex:indexPath.row];
            cell.textLabel.text = category.name;
        }
    } else if (self.viewMode == FacilitiesDisplaySubcategory) {
        FacilitiesCategory *category = [self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = category.name;
    } else if (self.viewMode == FacilitiesDisplayLocation) {
        FacilitiesLocation *location = [self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = location.name;
    } else if (self.viewMode == FacilitiesDisplayRoom) {
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Outside";
        } else {
            
        }
    }
    
    return cell;
}
@end
