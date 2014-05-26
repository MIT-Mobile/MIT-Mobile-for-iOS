//
//  PeopleSearchViewController_iPad.m
//  MIT Mobile
//
//  Created by YevDev on 5/25/14.
//
//

#import "PeopleSearchViewController_iPad.h"
#import "PeopleSearchResultsViewController.h"
#import "PeopleDetailsViewController.h"
#import "UIKit+MITAdditions.h"

@interface PeopleSearchViewController_iPad () <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UILabel *sampleSearchesLabel;
@property (nonatomic, weak) IBOutlet UIButton *emergencyContactsButton;

@property PeopleSearchResultsViewController *searchViewController;
@property PeopleDetailsViewController *searchDetailsViewController;

@end

@implementation PeopleSearchViewController_iPad

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
    
    UIBarButtonItem *favItem = [[UIBarButtonItem alloc] initWithTitle:@"Favorites" style:UIBarButtonItemStylePlain target:self action:@selector(handleFavorites)];
    [self.navigationItem setRightBarButtonItems:@[favItem]];

    // configure search bar to be in the center of navigaion bar.
    UIView *searchBarWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.navigationController.navigationBar.frame.size.height)];
    searchBarWrapperView.center = self.navigationController.navigationBar.center;
    
    self.searchDisplayController.searchBar.placeholder = @"Search People Directory";
    self.searchDisplayController.searchBar.frame = searchBarWrapperView.bounds;
    [searchBarWrapperView addSubview:self.searchDisplayController.searchBar];
    
    self.navigationItem.titleView = searchBarWrapperView;
    
    // configure main screen
    self.sampleSearchesLabel.text = @"Sample searches:\nName: 'william barton rogers', 'rogers'\nEmail: 'wbrogers', 'wbrogers@mit.edu'\nPhone: '6172531000', '31000'";
    [self.emergencyContactsButton setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
    
    [self configureChildControllers];
}

- (void) configureChildControllers
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) handleFavorites
{
    //todo
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ResultCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ResultCell"];
    }
    
    return cell;
}

#pragma mark - Search methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"");
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"");
}


@end
