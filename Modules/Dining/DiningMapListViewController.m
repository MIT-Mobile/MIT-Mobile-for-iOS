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
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
    [segmentControl addTarget:listView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) toggleMapList:(id)sender
{
    NSLog(@"Toggle the Map List");
    self.navigationItem.rightBarButtonItem.title = ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Map"])? @"List" : @"Map";
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
