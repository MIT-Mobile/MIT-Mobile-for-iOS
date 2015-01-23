#import "MITPeopleRecentResultsViewController.h"
#import "PeopleRecentSearchTerm.h"

@interface MITPeopleRecentResultsViewController () <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *recentResults;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;

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
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadRecentResultsWithFilterString:(NSString *)filterString
{
    self.recentResults = [self.searchHandler recentSearchTermsWithFilterString:filterString];
    
    [self.clearButton setEnabled:([self.recentResults count] > 0)];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}


#pragma mark - uitableview delegate methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recentResults count];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recentTableViewCell" forIndexPath:indexPath];
    
    PeopleRecentSearchTerm *recentTermObject = self.recentResults[indexPath.row];
    
    cell.textLabel.text = recentTermObject.recentSearchTerm;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PeopleRecentSearchTerm *recentTermObject = self.recentResults[indexPath.row];
    
    [self.delegate didSelectRecentSearchTerm:recentTermObject.recentSearchTerm];
}

- (IBAction)clearRecents:(id)sender
{
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *clearAllRecentsButtonTitle = NSLocalizedString(@"Clear All Recents", @"Clear All Recents button title");
    
    self.tableView.scrollEnabled = NO;
    
    UIActionSheet *confirmSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                              delegate:self
                                                     cancelButtonTitle:cancelButtonTitle
                                                destructiveButtonTitle:clearAllRecentsButtonTitle
                                                     otherButtonTitles:nil];
    [confirmSheet showInView:self.view];
}

#pragma mark - actionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tableView.scrollEnabled = YES;
    
    if( buttonIndex == actionSheet.cancelButtonIndex )
    {
        return;
    }
    
    if( ![self.searchHandler clearRecentSearches] )
    {
        // TODO: something went wrong.. handle error case
        
        return;
    }
    
    self.recentResults = nil;
    
    [self.clearButton setEnabled:NO];
    
    if ([self.delegate respondsToSelector:@selector(didClearRecents)]) {
        [self.delegate didClearRecents];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
