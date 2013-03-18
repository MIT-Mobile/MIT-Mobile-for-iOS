//
//  DiningMapListViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import "DiningMapListViewController.h"
#import "MITSegmentControl.h"
#import "MITMapView.h"

@interface DiningMapListViewController ()<UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView * listView;
    IBOutlet UISegmentedControl * segmentControl;
    IBOutlet MITMapView * mapView;
    
    BOOL isAnimating;
    BOOL isShowingMap;
}


@end

@implementation DiningMapListViewController

- (NSArray *) debugHouseDiningData
{
    return [NSArray arrayWithObjects:@"Baker", @"The Howard Dining Hall", @"McCormick", @"Next", @"Simmons", nil];
}

- (NSArray *) debugRetailDiningData
{
    return [NSArray arrayWithObjects:@"Anna's Taqueria", @"Cafe Spice", @"Cambridge Grill", @"Dunkin Donuts", @"LaVerde's Market", nil];
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
    
    [segmentControl addTarget:listView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self styleSegmentControl];
    
    [self layoutListState];
}

- (void) styleSegmentControl
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) toggleMapList:(id)sender
{
    if (!isAnimating) {
        NSLog(@"Toggle the Map List");
        self.navigationItem.rightBarButtonItem.title = (isShowingMap)? @"List" : @"Map";
        
        if (isShowingMap) {
            [UIView animateWithDuration:0.4f animations:^{
                listView.alpha = 1;
                mapView.alpha = 0;
                [self layoutListState];
                isAnimating = YES;
            } completion:^(BOOL finished) {
                isAnimating = NO;
            }];
            
        } else {
            mapView.alpha = 0;
            [UIView animateWithDuration:0.4f animations:^{
                listView.alpha = 0;
                mapView.alpha = 1;
                [self layoutMapState];
                isAnimating = YES;
            } completion:^(BOOL finished) {
                isAnimating = NO;
            }];
        }
        // toggle boolean flaggit 
        isShowingMap = !isShowingMap;
    }
}

#pragma mark - View layout

- (void) layoutListState
{
    segmentControl.center = CGPointMake(self.view.center.x, 30);
    
    listView.hidden = NO;
    listView.frame = CGRectMake(0, CGRectGetMaxY(segmentControl.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(segmentControl.frame));
    
    mapView.hidden = YES;
}

- (void) layoutMapState
{
    segmentControl.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 30);
    listView.hidden = YES;
    
    mapView.hidden = NO;
    mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *data = ([segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    
    return [data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"] autorelease];
    }
    
    NSArray *data = ([segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    cell.textLabel.text = [data objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
