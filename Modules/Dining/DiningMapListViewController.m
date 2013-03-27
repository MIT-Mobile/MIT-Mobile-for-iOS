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
    
    [_segmentControl addTarget:_listView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
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
    if (!_isAnimating) {
        NSLog(@"Toggle the Map List");
        self.navigationItem.rightBarButtonItem.title = (_isShowingMap)? @"List" : @"Map";
        
        if (_isShowingMap) {
            [UIView animateWithDuration:0.4f animations:^{
                _listView.alpha = 1;
                _mapView.alpha = 0;
                [self layoutListState];
                _isAnimating = YES;
            } completion:^(BOOL finished) {
                _isAnimating = NO;
            }];
            
        } else {
            _mapView.alpha = 0;
            [UIView animateWithDuration:0.4f animations:^{
                _listView.alpha = 0;
                _mapView.alpha = 1;
                [self layoutMapState];
                _isAnimating = YES;
            } completion:^(BOOL finished) {
                _isAnimating = NO;
            }];
        }
        // toggle boolean flaggit 
        _isShowingMap = !_isShowingMap;
    }
}

#pragma mark - View layout

- (void) layoutListState
{
    _segmentControl.center = CGPointMake(self.view.center.x, 30);
    
    _listView.hidden = NO;
    _listView.frame = CGRectMake(0, CGRectGetMaxY(_segmentControl.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(_segmentControl.frame));
    
    _mapView.hidden = YES;
}

- (void) layoutMapState
{
    _segmentControl.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 30);
    _listView.hidden = YES;
    
    _mapView.hidden = NO;
    _mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *data = ([_segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    
    return [data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
    }
    
    NSArray *data = ([_segmentControl selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    cell.textLabel.text = [data objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
