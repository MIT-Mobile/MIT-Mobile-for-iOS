#import "MITMobiusAdvancedSearchViewController.h"
#import "MITMobiusAttributesDataSource.h"
#import "UITableView+DynamicSizing.h"

@interface MITMobiusAdvancedSearchViewController () <UITableViewDataSourceDynamicSizing>
@property (nonatomic,strong) MITMobiusAttributesDataSource *dataSource;
@end

static NSString* const MITMobiusAdvancedSearchSelectedAttributeCellIdentifier = @"SelectedAttributeCellIdentifier";
static NSString* const MITMobiusAdvancedSearchAttributeCellIdentifier = @"AttributeCellIdentifier";

typedef NS_ENUM(NSInteger, MITMobiusAdvancedSearchSection) {
    MITMobiusAdvancedSearchSelectedAttributes,
    MITMobiusAdvancedSearchAttributes
};

@implementation MITMobiusAdvancedSearchViewController
- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }

    return self;
}

- (instancetype)initWithSearchText:(NSString *)searchText
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _searchText = [searchText copy];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.navigationController) {
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelButtonWasTapped:)];
        UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonWasTapped:)];

        [self.navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:animated];
        [self.navigationItem setRightBarButtonItem:doneBarButtonItem animated:animated];
    }

}

#pragma mark Interface Actions
- (IBAction)_cancelButtonWasTapped:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)_doneButtonWasTapped:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Data Updating

#pragma mark table helper methods
- (MITMobiusAdvancedSearchSection)_typeForSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return MITMobiusAdvancedSearchSelectedAttributes;

        case 1:
            return MITMobiusAdvancedSearchAttributes;

        default: {
            NSString *reason = [NSString stringWithFormat:@"unknown section with index %ld", (long)section];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }
    }
}

- (NSString*)_identifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAdvancedSearchSection section = [self _typeForSection:indexPath.section];

    switch (section) {
        case MITMobiusAdvancedSearchAttributes: {
            return MITMobiusAdvancedSearchAttributeCellIdentifier;
        }

        case MITMobiusAdvancedSearchSelectedAttributes: {
            return MITMobiusAdvancedSearchSelectedAttributeCellIdentifier;
        }
    }
}

#pragma mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MITMobiusAdvancedSearchSection sectionType = [self _typeForSection:section];

    switch (sectionType) {
        case MITMobiusAdvancedSearchAttributes:
            return 0;

        case MITMobiusAdvancedSearchSelectedAttributes:
            return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self _identifierForRowAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier]) {

    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchSelectedAttributes]) {

    } else {
        NSString *reason = [NSString stringWithFormat:@"unknown cell reuse identifier %@",cell.reuseIdentifier];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

#pragma mark UITableViewDataSource


@end