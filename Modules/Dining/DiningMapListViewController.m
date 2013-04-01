//
//  DiningMapListViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import "DiningMapListViewController.h"


#import "DiningMenuCompareViewController.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UISegmentedControl * segmentControl;
@property (nonatomic, strong) IBOutlet MITMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;

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
    
    [self.segmentControl addTarget:self.listView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self styleSegmentControl];
    
    [self layoutListState];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeLeft) {
        return YES;
    }
    return NO;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    DiningMenuCompareViewController *vc = [[DiningMenuCompareViewController alloc] init];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:vc animated:YES completion:NULL];
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
    if (!self.isAnimating) {
        NSLog(@"Toggle the Map List");
        self.navigationItem.rightBarButtonItem.title = (self.isShowingMap)? @"List" : @"Map";
        
        if (self.isShowingMap) {
            [UIView animateWithDuration:0.4f animations:^{
                self.listView.alpha = 1;
                self.mapView.alpha = 0;
                [self layoutListState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
            
        } else {
            self.mapView.alpha = 0;
            [UIView animateWithDuration:0.4f animations:^{
                self.listView.alpha = 0;
                self.mapView.alpha = 1;
                [self layoutMapState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
        }
        // toggle boolean flaggit 
        self.isShowingMap = !self.isShowingMap;
    }
}

#pragma mark - View layout

- (void) layoutListState
{
    self.segmentControl.center = CGPointMake(self.view.center.x, 30);
    
    self.listView.hidden = NO;
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.segmentControl.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.segmentControl.frame));
    
    self.mapView.hidden = YES;
}

- (void) layoutMapState
{
    self.segmentControl.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 30);
    self.listView.hidden = YES;
    
    self.mapView.hidden = NO;
    self.mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *data = ([self.segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    
    return [data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
    }
    
    NSArray *data = ([self.segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    cell.textLabel.text = [data objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
