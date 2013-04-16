//
//  DiningMapListViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import "DiningMapListViewController.h"
#import "DiningHallMenuViewController.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UISegmentedControl * segmentControl;
@property (nonatomic, strong) IBOutlet MGSMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;

@end

@implementation DiningMapListViewController

- (NSString *) debugAnnouncement
{
//    return nil;
    return @"ENROLL in the spring 2013 Meal Plan Program today! Or else you should be worried.";
}

- (NSArray *) debugHouseDiningData
{
    return [NSArray arrayWithObjects:@"Baker", @"The Howard Dining Hall", @"McCormick", @"Next", @"Simmons", nil];
}

- (NSArray *) debugRetailDiningData
{
    return [NSArray arrayWithObjects:@"Anna's Taqueria", @"Cafe Spice", @"Cambridge Grill", @"Dunkin Donuts", @"LaVerde's Market", nil];
}

- (NSArray *) debugResourceData
{
    return @[@"Meal Plan Balance", @"Comments for MIT Dining", @"Food to Go", @"Full MIT Dining Website"];
}

- (NSArray *) currentDiningData
{
    NSArray *data = ([self.segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
    [self.segmentControl addTarget:self.listView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self styleSegmentControl];
    
    self.listView.backgroundView = nil;
    
    [self layoutListState];
}

- (void) styleSegmentControl
{
    
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

#pragma mark - View layout

- (void) layoutListState
{
    self.segmentControl.center = CGPointMake(self.view.center.x, 30);
    
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.segmentControl.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.segmentControl.frame));
    
}

- (void) layoutMapState
{
    self.segmentControl.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 30);
    self.listView.center = CGPointMake(self.listView.center.x, self.listView.center.y + CGRectGetHeight(self.listView.bounds));
    
    self.mapView.hidden = NO;
    self.mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && indexPath.section == 0) {
        cell.textLabel.text = announcement;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
        cell.accessoryView = [self chevronAccessoryView];
    } else if((!announcement && indexPath.section == 0) || (announcement && indexPath.section == 1)) {
        cell.textLabel.text = [[self currentDiningData] objectAtIndex:indexPath.row];
    } else if ((!announcement && indexPath.section == 1)|| indexPath.section == 2) {
        cell.textLabel.text = [[self debugResourceData] objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *announcement = [self debugAnnouncement];
    if (announcement && section == 0) {
        return nil;
    } else if((!announcement && section == 0) || (announcement && section == 1)) {
        return [self.segmentControl titleForSegmentAtIndex:self.segmentControl.selectedSegmentIndex];
    } else if ((!announcement && section == 1)|| section == 2) {
        return @"Resources";
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *announcement = [self debugAnnouncement];
    if (announcement && indexPath.section == 0) {
        
    } else if((!announcement && indexPath.section == 0) || (announcement && indexPath.section == 1)) {
        DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
        detailVC.title = [self currentDiningData][indexPath.row];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else if ((!announcement && indexPath.section == 1)|| indexPath.section == 2) {
        
    }
    
}

@end
