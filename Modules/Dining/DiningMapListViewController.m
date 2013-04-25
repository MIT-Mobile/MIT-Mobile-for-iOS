//
//  DiningMapListViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import "DiningMapListViewController.h"
#import "DiningHallMenuViewController.h"
#import "DiningLocationCell.h"
#import "UIKit+MITAdditions.h"
#import "MITTabBar.h"
#import "FacilitiesLocationData.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UIView * tabContainerView;
@property (nonatomic, strong) IBOutlet MITTabBar * tabBar;
@property (nonatomic, strong) IBOutlet MGSMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;

@property (nonatomic, strong) NSDictionary * retailVenues;

@property (nonatomic, strong) NSDictionary * sampleData;

@end

@implementation DiningMapListViewController

- (NSString *) debugAnnouncement
{
//    return nil;
    return @"ENROLL in the spring 2013 Meal Plan Program today! Or else you should be worried.";
}

- (NSArray *) debugHouseDiningData
{
    return [NSArray arrayWithObjects:@"Baker", @"The Howard Dining Hall at Maseeh", @"McCormick", @"Next", @"Simmons", nil];
}

- (NSArray *) debugRetailDiningData
{
    return [NSArray arrayWithObjects:@"Anna's Taqueria", @"Cafe Spice", @"Cambridge Grill", @"Dunkin Donuts", @"LaVerde's Market", nil];
}

- (NSArray *) debugSubtitleData
{
    return @[@"12pm - 4pm", @"8pm - 4am, 9am - 12pm", @"10am - 2pm, 4pm - 7pm", @"8am - 2pm", @"7am - 9am, 2pm - 8pm, 5pm - 9pm"];
}

- (NSArray *) debugResourceData
{
    return @[@"Meal Plan Balance", @"Comments for MIT Dining", @"Food to Go", @"Full MIT Dining Website"];
}

- (NSArray *) currentDiningData
{
    NSArray *data = ([self.tabBar selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    return data;
}

- (UIView *) chevronAccessoryView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow.png"]];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dining-sample" ofType:@"json" inDirectory:@"dining"];
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
        NSError *error = nil;
        self.sampleData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
        }
        
        [self deriveRetailSections];
    }
    return self;
}

- (void) deriveRetailSections
{
    // Uses data from FacilitiesLocationData to get formal building names
    
    NSArray * buildingLocations = [[FacilitiesLocationData sharedData] locationsInCategory:@"building"];
    
    NSArray * retailLocations = self.sampleData[@"venues"][@"retail"];
    NSMutableDictionary *tempBuildings = [NSMutableDictionary dictionary];
    for (NSDictionary *venue in retailLocations) {
        NSString *buildingNumber = venue[@"location"][@"mit_building"];
        NSArray * results = [buildingLocations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"number == %@", buildingNumber]];
       
        // derive the section header name
        NSString * sectionKey;
        if ([results count] == 1) {
            NSString * buildingName = [[results lastObject] name];
            sectionKey = [NSString stringWithFormat:@"%@ - %@", buildingNumber, buildingName];

        } else if ([results count] == 0) {
            // need to handle if building is not found
            
        }
        
        // insert venue into correct section array
        if (tempBuildings[sectionKey]) {
            // either at end of section array
            NSMutableArray *venueArray = [tempBuildings[sectionKey] mutableCopy];
            [venueArray addObject:venue];
            tempBuildings[sectionKey] = venueArray;
            
        } else {
            // or in new section array
            tempBuildings[sectionKey] = @[venue];
        }
        
        
    }
    
    self.retailVenues = tempBuildings;
    
    
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Dining";

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
    [self.tabBar addTarget:self action:@selector(tabBarDidChange) forControlEvents:UIControlEventValueChanged];
    
    
    [self addTabWithTitle:@"House Dining"];
    [self addTabWithTitle:@"Retail"];
    self.tabBar.selectedSegmentIndex = 0;
    
    self.listView.backgroundView = nil;
    
    [self layoutListState];
}

- (void) addTabWithTitle:(NSString *)title
{
    NSInteger index = [self.tabBar.items count];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:nil tag:index];
    [self.tabBar insertSegmentWithItem:item atIndex:index animated:NO];
    
}

- (void) tabBarDidChange
{
    [self.listView reloadData];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) toggleMapList:(id)sender
{
    if (!self.isAnimating) {
        NSLog(@"Toggle the Map List");
        self.navigationItem.rightBarButtonItem.title = (self.isShowingMap)? @"Map" : @"List";
        
        if (self.isShowingMap) {
            // animate to the list
            self.listView.center = CGPointMake(self.view.center.x, self.view.center.y + CGRectGetHeight(self.view.bounds));
            [UIView animateWithDuration:0.4f animations:^{
                self.mapView.alpha = 0;
                [self layoutListState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
            
        } else {
            // animate to the map
            self.mapView.alpha = 0;
            [UIView animateWithDuration:0.4f animations:^{
                self.mapView.alpha = 1;
                [self layoutMapState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
        }
        // toggle boolean flag 
        self.isShowingMap = !self.isShowingMap;
    }
}

- (BOOL) showingHouseDining
{
    return (self.tabBar.selectedSegmentIndex == 0);
}

#pragma mark - View layout

- (void) layoutListState
{
    self.tabContainerView.center = CGPointMake(self.view.center.x, 25);
    
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.tabContainerView.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.tabContainerView.frame));
    
}

- (void) layoutMapState
{
    self.tabContainerView.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 25);
    
    self.listView.center = CGPointMake(self.listView.center.x, self.listView.center.y + CGRectGetHeight(self.listView.bounds));
    
    self.mapView.hidden = NO;
    self.mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:section];
        return [self.retailVenues[sectionKey] count];
    }
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && section == 0) {
        return 1;
    } else if((!announcement && section == 0) || (announcement && section == 1)) {
            return [[self currentDiningData] count];
    } else if ((!announcement && section == 1)|| section == 2) {
        return [[self debugResourceData] count];
    }
    return 0;   
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (![self showingHouseDining]) {
        return [[self.retailVenues allKeys] count];
    }
    
    if ([self debugAnnouncement]) {
        return 3;
    }
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
    }
    
    if (![self showingHouseDining]) {
        // showing Retail locations
        return [self tableView:tableView retailDiningLocationCellForRowAtIndexPath:indexPath];
    }
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && indexPath.section == 0) {
        cell.textLabel.text = announcement;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
        cell.accessoryView = [self chevronAccessoryView];
    } else if((!announcement && indexPath.section == 0) || (announcement && indexPath.section == 1)) {
        return [self tableView:tableView houseDiningLocationCellForRowAtIndexPath:indexPath];
    } else if ((!announcement && indexPath.section == 1)|| indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
        } else {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        }
        cell.textLabel.text = [[self debugResourceData] objectAtIndex:indexPath.row];
    }
    
    return cell;
}

#pragma mark Configure House Dining Cell
- (UITableViewCell *) tableView:(UITableView *)tableView houseDiningLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiningLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
    if (!cell) {
        cell = [[DiningLocationCell alloc] initWithReuseIdentifier:@"locationCell"];
    }
    
    cell.titleLabel.text = [self currentDiningData][indexPath.row];
    cell.subtitleLabel.text = [self debugSubtitleData][indexPath.row];
    cell.statusOpen = indexPath.row % 2 == 0;
    cell.accessoryView = [self chevronAccessoryView];
    cell.imageView.image = [UIImage imageNamed:@"icons/home-about.png"];
    
    return cell;
}

#pragma mark Configure Retail Cell
- (UITableViewCell *) tableView:(UITableView *)tableView retailDiningLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiningLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
    if (!cell) {
        cell = [[DiningLocationCell alloc] initWithReuseIdentifier:@"locationCell"];
    }
    
    
    
    NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
    NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
    
    cell.titleLabel.text = venueData[@"name"];
    cell.subtitleLabel.text = [self debugSubtitleData][indexPath.row];
    cell.statusOpen = indexPath.row % 2 == 0;
    cell.accessoryView = [self chevronAccessoryView];
    cell.imageView.image = [UIImage imageNamed:@"icons/home-map.png"];
    
    
    return cell;
}


- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (![self showingHouseDining]) {
        return [[self.retailVenues allKeys] objectAtIndex:section];
    }
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && section == 0) {
        return nil;
    } else if((!announcement && section == 0) || (announcement && section == 1)) {
            return @"Venues";
    } else if ((!announcement && section == 1)|| section == 2) {
        return @"Resources";
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
        NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
        
        DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
        detailVC.title = venueData[@"name"];
        [self.navigationController pushViewController:detailVC animated:YES];
        return;
    }
    

    NSString *announcement = [self debugAnnouncement];
    if (announcement && indexPath.section == 0) {
        
    } else if((!announcement && indexPath.section == 0) || (announcement && indexPath.section == 1)) {
        DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
        detailVC.title = [self currentDiningData][indexPath.row];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else if ((!announcement && indexPath.section == 1)|| indexPath.section == 2) {
        // handle static links
        
    }
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
        NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
        return [DiningLocationCell heightForRowWithTitle:venueData[@"name"] subtitle:[self debugSubtitleData][indexPath.row]];
    }
    
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && indexPath.section == 0) {
        return 44;
    } else if((!announcement && indexPath.section == 0) || (announcement && indexPath.section == 1)) {
        return [DiningLocationCell heightForRowWithTitle:[self currentDiningData][indexPath.row] subtitle:[self debugSubtitleData][indexPath.row]];
    } else if ((!announcement && indexPath.section == 1)|| indexPath.section == 2) {
        return 44;
    }
    return 44;
}

@end

