#import "MITMapTypeAheadTableViewController.h"
#import "MITMapModelController.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"

static NSString * const kMITMapPlaceDefaultCellIdentifier = @"kMITMapPlaceDefaultCellIdentifier";

@interface MITMapTypeAheadTableViewController ()

@property (nonatomic, strong) NSArray *recentSearchItems;
@property (nonatomic, strong) NSArray *webserviceSearchItems;
@property (nonatomic, strong) NSString *currentSearchString;

@end

@implementation MITMapTypeAheadTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Public Methods

- (void)updateResultsWithSearchTerm:(NSString *)searchTerm
{
    if ([searchTerm isEqualToString:@""]) {
        searchTerm = nil;
    }
    
    self.currentSearchString = searchTerm;
    
    [self showTitleHeaderIfNecessary];
    
    __weak MITMapTypeAheadTableViewController *blockSelf = self;
    
    // The error cases in these blocks are left unhandled on purpose for now. Not sure if the user ever needs to be informed
    [[MITMapModelController sharedController] recentSearchesForPartialString:searchTerm loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (![blockSelf isCurrentSearchStringEqualTo:searchTerm]) {
            return;
        }
        if (fetchRequest) {
            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            [[MITCoreDataController defaultController] performBackgroundFetch:fetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
                if (![blockSelf isCurrentSearchStringEqualTo:searchTerm]) {
                    return;
                }
                self.recentSearchItems = [managedObjectContext objectsWithIDs:[fetchedObjectIDs array]];
                [self.tableView reloadData];
            }];
        }
    }];
    
    if (searchTerm) {
        [[MITMapModelController sharedController] searchMapWithQuery:searchTerm loaded:^(NSArray *objects, NSError *error) {
            if (![blockSelf isCurrentSearchStringEqualTo:searchTerm]) {
                return;
            }
            self.webserviceSearchItems = objects;
            [self.tableView reloadData];
        }];
    }
}

- (BOOL)isCurrentSearchStringEqualTo:(NSString *)searchString
{
    if (searchString == nil && self.currentSearchString == nil) {
        return YES;
    } else if ([searchString isEqualToString:self.currentSearchString]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)showTitleHeaderIfNecessary
{
    if (self.showsTitleHeader) {
        if (self.currentSearchString == nil || self.currentSearchString.length < 1) {
            [self showRecentsHeader];
        } else {
            [self showSuggestionsHeader];
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)setShowsTitleHeader:(BOOL)showsTitleHeader
{
    _showsTitleHeader = showsTitleHeader;
    
    [self showTitleHeaderIfNecessary];
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
        clearButton.titleLabel.textColor = [UIColor mit_tintColor];
        //TODO: make this button clear the recent searches, once this functionality exists
        [recentsHeaderView addSubview:clearButton];
        
        UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(0, recentsHeaderView.bounds.size.height - 1, recentsHeaderView.bounds.size.width, 0.5)];
        dividerLine.backgroundColor = [UIColor lightGrayColor];
        [recentsHeaderView addSubview:dividerLine];
    }
    
    self.tableView.tableHeaderView = recentsHeaderView;
}

- (void)showSuggestionsHeader
{
    static UIView *suggestionsHeaderView;
    
    if (!suggestionsHeaderView) {
        suggestionsHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:suggestionsHeaderView.bounds];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        titleLabel.text = @"Suggestions";
        [suggestionsHeaderView addSubview:titleLabel];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [suggestionsHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleLabel(>=0)]-0-|" options:0 metrics:nil views:@{@"titleLabel": titleLabel}]];
        [suggestionsHeaderView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleLabel(>=0)]-0-|" options:0 metrics:nil views:@{@"titleLabel": titleLabel}]];
        
        UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(0, suggestionsHeaderView.bounds.size.height - 1, suggestionsHeaderView.bounds.size.width, 0.5)];
        dividerLine.backgroundColor = [UIColor lightGrayColor];
        [suggestionsHeaderView addSubview:dividerLine];
    }
    
    self.tableView.tableHeaderView = suggestionsHeaderView;
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
        case 1: {
            MITMapPlace *place = self.webserviceSearchItems[indexPath.row];
            if ([self.delegate respondsToSelector:@selector(typeAheadViewController:didSelectPlace:)]) {
                [self.delegate typeAheadViewController:self didSelectPlace:place];
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return self.recentSearchItems.count;
            break;
        }
        case 1: {
            return self.webserviceSearchItems.count;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapPlaceDefaultCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITMapPlaceDefaultCellIdentifier];
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
        case 1: {
            MITMapPlace *place = self.webserviceSearchItems[indexPath.row];
            cell.textLabel.text = place.name;
            break;
        }
        default: {
            break;
        }
    }
    
    return cell;
}

@end
