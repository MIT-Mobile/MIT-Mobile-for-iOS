#import "MITMapRecentsTableViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITMapModelController.h"
#import "CoreData+MITAdditions.h"

NSString * const kMITMapRecentSearchCellIdentifier = @"kMITMapRecentSearchCellIdentifier";

@interface MITMapRecentsTableViewController ()

@end

@implementation MITMapRecentsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reloadAllRecents];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods

- (void)setShowsTitleHeader:(BOOL)showsTitleHeader
{
    _showsTitleHeader = showsTitleHeader;
    
    [self showTitleHeaderIfNecessary];
}

- (void)showTitleHeaderIfNecessary
{
    if (self.showsTitleHeader) {
        [self showRecentsHeader];
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - Private Methods

- (void)reloadAllRecents
{
    [[MITMapModelController sharedController] recentSearches:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (fetchRequest) {
            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            [[MITCoreDataController defaultController] performBackgroundFetch:fetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
                self.recentSearchItems = [managedObjectContext objectsWithIDs:[fetchedObjectIDs array]];
                [self.tableView reloadData];
            }];
        }
    }];
}

- (void)showRecentsHeader
{
    static UIView *recentsHeaderView;
    
    if (!recentsHeaderView) {
        recentsHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:recentsHeaderView.bounds];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        titleLabel.text = @"Recents";
        [recentsHeaderView addSubview:titleLabel];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [recentsHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleLabel(>=0)]-0-|" options:0 metrics:nil views:@{@"titleLabel": titleLabel}]];
        [recentsHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleLabel(>=0)]-0-|" options:0 metrics:nil views:@{@"titleLabel": titleLabel}]];
        
        UIButton *clearButton = [[UIButton alloc] init];
        CGSize buttonTextSize = [@"Clear" sizeWithFont:clearButton.titleLabel.font];
        clearButton.frame = CGRectMake(20, 0, buttonTextSize.width, 44);
        [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
        [clearButton setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
        [clearButton addTarget:self action:@selector(clearRecentSearchesButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [recentsHeaderView addSubview:clearButton];
        
        UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(0, recentsHeaderView.bounds.size.height - 1, recentsHeaderView.bounds.size.width, 0.5)];
        dividerLine.backgroundColor = [UIColor lightGrayColor];
        [recentsHeaderView addSubview:dividerLine];
    }
    
    self.tableView.tableHeaderView = recentsHeaderView;
}

- (void)clearRecentSearchesButtonTapped:(id)sender
{
    [[MITMapModelController sharedController] clearRecentSearchesWithCompletion:^(NSError *error) {
        [self reloadAllRecents];
    }];
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            MITMapSearch *searchItem = self.recentSearchItems[indexPath.row];
            if (searchItem.searchTerm) {
                if ([self.delegate respondsToSelector:@selector(typeAheadViewController:didSelectRecentQuery:)]) {
                    [self.delegate typeAheadViewController:self didSelectRecentQuery:searchItem.searchTerm];
                }
            } else if (searchItem.place) {
                if ([self.delegate respondsToSelector:@selector(typeAheadViewController:didSelectPlace:)]) {
                    [self.delegate typeAheadViewController:self didSelectPlace:searchItem.place];
                }
            } else if (searchItem.category) {
                if ([self.delegate respondsToSelector:@selector(typeAheadViewController:didSelectCategory:)]) {
                    [self.delegate typeAheadViewController:self didSelectCategory:searchItem.category];
                }
            }
            break;
        }
        default: {
            break;
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return self.recentSearchItems.count;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapRecentSearchCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITMapRecentSearchCellIdentifier];
    }
    
    switch (indexPath.section) {
        case 0: {
            MITMapSearch *searchItem = self.recentSearchItems[indexPath.row];
            if (searchItem.searchTerm) {
                cell.textLabel.text = searchItem.searchTerm;
            } else if (searchItem.place) {
                cell.textLabel.text = searchItem.place.name;
            } else if (searchItem.category) {
                cell.textLabel.text = searchItem.category.name;
            }
            break;
        }
        default: {
            break;
        }
    }
    
    return cell;
}

@end