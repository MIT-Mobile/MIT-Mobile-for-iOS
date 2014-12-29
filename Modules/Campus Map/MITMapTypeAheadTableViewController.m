#import "MITMapTypeAheadTableViewController.h"
#import "MITMapModelController.h"
#import "CoreData+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface MITMapTypeAheadTableViewController ()

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
    } else {
        self.webserviceSearchItems = nil;
        [self.tableView reloadData];
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
            [super showTitleHeaderIfNecessary];
        } else {
            [self showSuggestionsHeader];
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }
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
    if (indexPath.section < [super numberOfSectionsInTableView:tableView]) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else {
        MITMapPlace *place = self.webserviceSearchItems[indexPath.row];
        if ([self.delegate respondsToSelector:@selector(placeSelectionViewController:didSelectPlace:)]) {
            [self.delegate placeSelectionViewController:self didSelectPlace:place];
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [super numberOfSectionsInTableView:tableView] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < [super numberOfSectionsInTableView:tableView]) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        return self.webserviceSearchItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < [super numberOfSectionsInTableView:tableView]) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapRecentSearchCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITMapRecentSearchCellIdentifier];
        }
        cell.imageView.image = [UIImage imageNamed:MITImageMapAnnotationPlacePin];
        MITMapPlace *place = self.webserviceSearchItems[indexPath.row];
        cell.textLabel.text = place.name;
        
        return cell;
    }
}

@end
