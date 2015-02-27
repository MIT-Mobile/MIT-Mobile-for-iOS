#import "MITMartyRecentSearchController.h"
#import "MITMartyResourceDataSource.h"
#import "MITNewsRecentSearchQuery.h"
#import "UIKit+MITAdditions.h"

@interface MITMartyRecentSearchController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) MITMartyResourceDataSource *modelController;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readwrite) UIActionSheet *confirmSheet;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *clearButtonItem;
@property (nonatomic, strong) NSString *filterString;
@property (nonatomic, strong) NSArray *recentResults;

@end

@implementation MITMartyRecentSearchController

@synthesize delegate = _delegate;

#pragma mark - properties
- (MITMartyResourceDataSource *)modelController
{
    if(!_modelController) {
        MITMartyResourceDataSource *modelController = [[MITMartyResourceDataSource alloc] init];
        _modelController = modelController;
    }
    return _modelController;
}

#pragma mark - View lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.recentResults = [self.modelController recentSearchItemswithFilterString:self.filterString];
    if ([self.recentResults count] == 0) {
        self.clearButtonItem.enabled = NO;
    }
    
    self.clearButtonItem.tintColor = [UIColor mit_tintColor];
    self.navigationItem.leftBarButtonItem = self.clearButtonItem;
    self.navigationItem.title = @"Recents";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Recent Add/Remove methods
- (IBAction)clearRecentsButtonClicked:(id)sender
{
    self.confirmSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear All Recents" otherButtonTitles:nil];
    [self.confirmSheet showInView:self.view];
}

- (void)addRecentSearchItem:(NSString *)searchTerm
{
    NSError *error = nil;
    [self.modelController addRecentSearchItem:searchTerm error:error];
    self.recentResults = [self.modelController recentSearchItemswithFilterString:self.filterString];
    self.clearButtonItem.enabled = YES;
}

- (void)filterResultsUsingString:(NSString *)filterString
{
    self.recentResults = [self.modelController recentSearchItemswithFilterString:filterString];
    self.filterString = filterString;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [self clearRecents];
    }
    self.confirmSheet = nil;
}

- (void)clearRecents
{
    NSError *error = nil;
    [self.modelController clearRecentSearchesWithError:error];
    self.recentResults = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
    self.clearButtonItem.enabled = NO;
}

#pragma mark - Table View methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    MITNewsRecentSearchQuery *query = self.recentResults[indexPath.row];
    cell.textLabel.text = query.text;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recentResults count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MITNewsRecentSearchQuery *query = self.recentResults[indexPath.row];
    NSError *error = nil;
    [self.modelController addRecentSearchItem:query.text error:error];
    
    if ([self.delegate respondsToSelector:@selector(placeSelectionViewController:didSelectQuery:)]) {
        [self.delegate placeSelectionViewController:self didSelectQuery:query.text];
    }
    
    [self filterResultsUsingString:query.text];

}
@end
