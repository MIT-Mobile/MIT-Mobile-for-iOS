#import "MITMapResultsListViewController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITMapNumberedResultCell.h"
#import "MITMapPlaceDetailViewController.h"

static NSString * const kMITMapNumberedResultCellIdentifier = @"MITMapNumberedResultCell";

@interface MITMapResultsListViewController ()

@property (nonatomic, strong) MITMapNumberedResultCell *helperCell;

@end

@implementation MITMapResultsListViewController

#pragma mark - Init

- (instancetype)initWithPlaces:(NSArray *)places
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _places = places;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
    [self setupDoneBarButtonItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Update helper cell frame
    CGRect frame = self.helperCell.frame;
    frame.size.width = self.tableView.frame.size.width;
    self.helperCell.frame = frame;
    
    // Reload cell heights
    [self.tableView reloadData];
}

#pragma mark - Setup

- (void)setupTableView
{
    UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITMapNumberedResultCell class]) bundle:nil];
    [self.tableView registerNib:numberedResultCellNib forCellReuseIdentifier:kMITMapNumberedResultCellIdentifier];
    
    self.helperCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
}

- (void)setupDoneBarButtonItem
{
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemTapped:)];
    self.navigationItem.rightBarButtonItem = doneButtonItem;
}

#pragma mark - Button Actions

- (void)doneBarButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Title

- (void)setTitleWithSearchQuery:(NSString *)query
{
    self.navigationItem.title = query ? [NSString stringWithFormat:@"\"%@\"", query] : nil;
}

#pragma mark - Table View Helpers

- (void)configureCell:(MITMapNumberedResultCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    [cell setPlace:self.places[index] order:(index + 1)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.places count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapNumberedResultCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapNumberedResultCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kMapNumberedResultCellEstimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.helperCell forIndexPath:indexPath];
    [self.helperCell layoutIfNeeded];
    
    CGFloat height = [self.helperCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(resultsListViewController:didSelectPlace:)]) {
            MITMapPlace *place = self.places[indexPath.row];
            [self.delegate resultsListViewController:self didSelectPlace:place];
        }
    }];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlace *place = self.places[indexPath.row];
    MITMapPlaceDetailViewController *detailVC = [[MITMapPlaceDetailViewController alloc] initWithNibName:nil bundle:nil];
    detailVC.place = place;
    [self.navigationController pushViewController:detailVC animated:YES];
}

@end
