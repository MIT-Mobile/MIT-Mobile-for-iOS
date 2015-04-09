#import "MITMobiusAdvancedSearchViewController.h"
#import "MITMobiusAttributesDataSource.h"
#import "UITableView+DynamicSizing.h"
#import "MITMobiusModel.h"

@interface MITMobiusAdvancedSearchViewController () <UITableViewDataSourceDynamicSizing>
@property (nonatomic,strong) MITMobiusAttributesDataSource *dataSource;
@end

static NSString* const MITMobiusAdvancedSearchSelectedAttributeCellIdentifier = @"SelectedAttributeCellIdentifier";
static NSString* const MITMobiusAdvancedSearchAttributeCellIdentifier = @"AttributeCellIdentifier";
static NSString* const MITMobiusAdvancedSearchAttributeValueCellIdentifier = @"AttributeValueCellIdentifier";

typedef NS_ENUM(NSInteger, MITMobiusAdvancedSearchSection) {
    MITMobiusAdvancedSearchSelectedAttributes,
    MITMobiusAdvancedSearchAttributes
};

@interface MITMobiusAdvancedSearchViewController ()

@end

@implementation MITMobiusAdvancedSearchViewController
- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _dataSource = [[MITMobiusAttributesDataSource alloc] init];
    }

    return self;
}

- (instancetype)initWithSearchText:(NSString *)searchText
{
    self = [self initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _searchText = [searchText copy];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeValueCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.navigationController) {
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelButtonWasTapped:)];
        UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonWasTapped:)];

        [self.navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:animated];
        [self.navigationItem setRightBarButtonItem:doneBarButtonItem animated:animated];
    }
    
    [self.dataSource attributes:^(MITMobiusAttributesDataSource *dataSource, NSError *error) {
        [self.tableView reloadData];
    }];

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
            return self.dataSource.attributes.count;

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier]) {

    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeCellIdentifier]) {
        MITMobiusAttribute *attribute = self.dataSource.attributes[indexPath.row];
        cell.textLabel.text = attribute.label;
        
        BOOL isAttributeExpanded = NO;
        UIImage *image = nil;
        if (isAttributeExpanded) {
            image = [UIImage imageNamed:MITImageDisclosureRight];
        } else {
            image = [UIImage imageNamed:MITImageNameRightArrow];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeValueCellIdentifier]) {
        MITMobiusAttributeValue *value = [self attributeValueForIndexPath:indexPath];
    } else {
        NSString *reason = [NSString stringWithFormat:@"unknown cell reuse identifier %@",cell.reuseIdentifier];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end

@interface MITMobiusAttributeElement
@property (nonatomic,readonly,strong)
- (instancetype)initWithAttribute:(MITMobiusAttribute*)attribute;
@end