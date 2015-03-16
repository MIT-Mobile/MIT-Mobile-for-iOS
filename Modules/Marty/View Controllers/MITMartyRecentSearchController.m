#import "MITMartyRecentSearchController.h"
#import "MITMartyResourceDataSource.h"
#import "MITNewsRecentSearchQuery.h"
#import "UIKit+MITAdditions.h"

@interface MITMartyRecentSearchController () <UIActionSheetDelegate>
@property (nonatomic,strong) MITMartyResourceDataSource *modelController;
@property (nonatomic,weak) UIActionSheet *confirmSheet;
@property (nonatomic,copy) NSString *filterString;
@property (nonatomic,copy) NSArray *recentResults;
@property (nonatomic,weak) UIBarButtonItem *clearButtonItem;

@end

@implementation MITMartyRecentSearchController

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
    
    UIBarButtonItem *clearButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearRecentsButtonClicked:)];
    
    if ([self.recentResults count] == 0) {
        clearButtonItem.enabled = NO;
    }
    
    self.navigationItem.title = @"Recents";
    self.navigationItem.leftBarButtonItem = clearButtonItem;
    self.clearButtonItem = clearButtonItem;
    
    self.navigationController.navigationBar.tintColor = [UIColor mit_tintColor];
    self.view.tintColor = [UIColor mit_tintColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.confirmSheet) {
        [self.confirmSheet dismissWithClickedButtonIndex:self.confirmSheet.cancelButtonIndex animated:animated];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Recent Add/Remove methods
- (IBAction)clearRecentsButtonClicked:(id)sender
{
    UIActionSheet *actionSheet =  [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:@"Clear All Recents"
                                                     otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    self.confirmSheet = actionSheet;
}

- (void)filterResultsUsingString:(NSString *)filterString
{
    self.recentResults = [self.modelController recentSearchItemswithFilterString:filterString];
    
    NSInteger numberOfRecentResults = [self.modelController numberOfRecentSearchItemsWithFilterString:filterString];
    
    if (numberOfRecentResults > 0) {
        self.clearButtonItem.enabled = YES;
    }
    self.filterString = filterString;
    [self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self clearRecents];
    }
    
    self.confirmSheet = nil;
}

- (void)clearRecents
{
    [self.modelController clearRecentSearches];
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
    [self.modelController addRecentSearchItem:query.text error:nil];
    
    if ([self.delegate respondsToSelector:@selector(placeSelectionViewController:didSelectQuery:)]) {
        [self.delegate placeSelectionViewController:self didSelectQuery:query.text];
    }
    
    [self filterResultsUsingString:query.text];
}

@end
