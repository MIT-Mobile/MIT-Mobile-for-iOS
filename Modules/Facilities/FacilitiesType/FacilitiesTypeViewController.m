//
//  FacilitiesTypeViewController.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/5/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "FacilitiesTypeViewController.h"
#import "FacilitiesSummaryViewController.h"
#import "FacilitiesConstants.h"

@implementation FacilitiesTypeViewController
@synthesize userData = _userData;
@synthesize tableView = _tableView;

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"What is it?";
        self.userData = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.userData = nil;
    self.tableView = nil;
    self.view = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSArray*)repairTypes {
    static NSArray *types = nil;
    
    if (types == nil) {
        types = [[NSArray alloc] initWithObjects:@"Clock", @"Door",
                 @"Floor",@"Light",
                 @"Parking Garage/Lot",@"Restroom",
                 @"Sign",@"Trash/Recycling",
                 @"Window",@"Other",nil];
    }
    
    return [NSArray arrayWithArray:types];
}

#pragma mark - View lifecycle
- (void)loadView {
    UIView *mainView = nil;
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    {
        mainView = [[[UIView alloc] initWithFrame:screenRect] autorelease];
        mainView.autoresizesSubviews = YES;
        mainView.backgroundColor = [UIColor clearColor];
    }
    
    {
        CGRect tableRect = screenRect;
        tableRect.origin = CGPointZero;
        
        UITableView *table = [[[UITableView alloc] initWithFrame:tableRect
                                                           style:UITableViewStyleGrouped] autorelease];
        table.delegate = self;
        table.dataSource = self;
        table.hidden = NO;
        
        self.tableView = table;
        [mainView addSubview:table];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self repairTypes] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"typeCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.textLabel.text = [[self repairTypes] objectAtIndex:indexPath.row];

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.userData];
    [dict setObject:[[self repairTypes] objectAtIndex:indexPath.row]
             forKey:FacilitiesRequestRepairTypeKey];
    
    FacilitiesSummaryViewController *vc = [[[FacilitiesSummaryViewController alloc] init] autorelease];
    vc.reportData = dict;
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

@end
