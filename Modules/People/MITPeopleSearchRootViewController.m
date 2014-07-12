//
//  MITPeopleSearchRootViewController.m
//  MIT Mobile
//
//  Created by Yev Motov on 7/12/14.
//
//

#import "MITPeopleSearchRootViewController.h"

@interface MITPeopleSearchRootViewController () <UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barItem;

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation MITPeopleSearchRootViewController

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
    
    [self configureNavigationBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - configs

- (void)configureNavigationBar
{
    // favorites button
    [self.barItem setTitle:@"Favorites"];
    [self.barItem setTarget:self];
    [self.barItem setAction:@selector(handleFavorites)];
    [self.navigationItem setRightBarButtonItems:@[self.barItem]];
    
    // configure search bar to be in the center of navigaion bar.
    UIView *searchBarWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, self.navigationController.navigationBar.frame.size.height)];
    searchBarWrapperView.center = self.navigationController.navigationBar.center;
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"Search People Directory";
    self.searchBar.frame = searchBarWrapperView.bounds;
    self.searchBar.delegate = self;
    [searchBarWrapperView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarWrapperView;
}

#pragma mark - actions

- (void) handleFavorites
{
    [self performSegueWithIdentifier:@"MITFavoritesSegue" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
