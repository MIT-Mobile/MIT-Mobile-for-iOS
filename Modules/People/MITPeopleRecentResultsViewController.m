//
//  MITPeopleRecentResultsViewController.m
//  MIT Mobile
//
//  Created by YevDev on 6/15/14.
//
//

#import "MITPeopleRecentResultsViewController.h"
#import "PeopleRecentsData.h"

@interface MITPeopleRecentResultsViewController ()

@end

@implementation MITPeopleRecentResultsViewController

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
    // Do any additional setup after loading the view.
    
    // hardcoded values for now
    self.preferredContentSize = CGSizeMake(280, 300);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - uitableview delegate methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[PeopleRecentsData sharedData] recents] count];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recentTableViewCell" forIndexPath:indexPath];
    
    NSArray *recentPeople = [[PeopleRecentsData sharedData] recents];
    
    if (indexPath.row < [recentPeople count]) {
        PersonDetails *recent = recentPeople[indexPath.row];
        cell.textLabel.text = recent.name;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *recentPeople = [[PeopleRecentsData sharedData] recents];
    
    if (indexPath.row < [recentPeople count]) {
        PersonDetails *recent = recentPeople[indexPath.row];
        
        [self.delegate didSelectRecentPerson:recent];
    }
}

- (IBAction)clearRecents:(id)sender
{
    [PeopleRecentsData eraseAll];
    
    [self.tableView reloadData];
    
    [self.delegate didClearRecents];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
