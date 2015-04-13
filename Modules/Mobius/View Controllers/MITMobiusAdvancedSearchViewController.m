#import "MITMobiusAdvancedSearchViewController.h"
#import "MITMobiusAttributesDataSource.h"
#import "MITMobiusModel.h"

@interface MITMobiusAdvancedSearchViewController ()
@property (nonatomic,strong) MITMobiusAttributesDataSource *dataSource;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) MITMobiusRecentSearchQuery *query;
@end

static NSString* const MITMobiusAdvancedSearchSelectedAttributeCellIdentifier = @"SelectedAttributeCellIdentifier";
static NSString* const MITMobiusAdvancedSearchAttributeCellIdentifier = @"AttributeCellIdentifier";
static NSString* const MITMobiusAdvancedSearchAttributeValueCellIdentifier = @"AttributeValueCellIdentifier";

typedef NS_ENUM(NSInteger, MITMobiusAdvancedSearchSection) {
    MITMobiusAdvancedSearchSelectedAttributes,
    MITMobiusAdvancedSearchAttributes
};

@interface MITMobiusAdvancedSearchViewController ()
@property (nonatomic,strong) NSIndexPath *currentExpandedIndexPath;
@end

@implementation MITMobiusAdvancedSearchViewController
- (instancetype)init
{
    self = [self initWithQuery:nil];

    if (self) {

    }

    return self;
}

- (instancetype)initWithQuery:(MITMobiusRecentSearchQuery *)query
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    if (self) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.parentContext = [MITCoreDataController defaultController].mainQueueContext;
        _dataSource = [[MITMobiusAttributesDataSource alloc] initWithManagedObjectContext:_managedObjectContext];

        if (query) {
            _query = (MITMobiusRecentSearchQuery*)[_managedObjectContext existingObjectWithID:query.objectID error:nil];
        } else {
            _query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext insertNewObjectForEntityForName:[MITMobiusRecentSearchQuery entityName]];
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeValueCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.query.isUpdated || self.query.isNew) {
        [self.managedObjectContext saveToPersistentStore:nil];
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
- (void)_collapseItemAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];

    NSMutableArray *deletionIndexPaths = [[NSMutableArray alloc] init];
    NSRange deletionRange = NSMakeRange(indexPath.row + 1, attribute.values.count);
    NSIndexSet *deletionIndexSet = [NSIndexSet indexSetWithIndexesInRange:deletionRange];
    [deletionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [deletionIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:indexPath.section]];
    }];

    [self.tableView deleteRowsAtIndexPaths:deletionIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)_expandItemAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];

    NSMutableArray *insertionIndexPaths = [[NSMutableArray alloc] init];
    NSRange insertionRange = NSMakeRange(indexPath.row + 1, attribute.values.count);
    NSIndexSet *insertionIndexSet = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
    [insertionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [insertionIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:indexPath.section]];
    }];

    [self.tableView insertRowsAtIndexPaths:insertionIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark table helper methods
- (NSIndexPath*)indexPathForAttribute:(MITMobiusAttribute*)attribute
{
    NSUInteger attributesSection = 1;
    NSUInteger indexOfAttribute = [self.dataSource.attributes indexOfObject:attribute];

    if (self.currentExpandedIndexPath) {
        if (indexOfAttribute > self.currentExpandedIndexPath.row) {
            MITMobiusAttribute *expandedAttribute = [self attributeForIndexPath:self.currentExpandedIndexPath];
            NSUInteger row = indexOfAttribute - expandedAttribute.values.count;
            return [NSIndexPath indexPathForRow:row inSection:attributesSection];
        }

    }

    return [NSIndexPath indexPathForRow:indexOfAttribute inSection:attributesSection];
}

- (MITMobiusAttribute*)attributeForIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAdvancedSearchSection section = [self _typeForSection:indexPath.section];
    NSAssert(section == MITMobiusAdvancedSearchAttributes, @"attempting to get an attribute for an invalid section");

    NSUInteger targetRow = indexPath.row;

    if (self.currentExpandedIndexPath) {
        MITMobiusAttribute *expandedAttribute = self.dataSource.attributes[self.currentExpandedIndexPath.row];
        NSRange attributeValueRange = NSMakeRange(self.currentExpandedIndexPath.row + 1, expandedAttribute.values.count);

        if (NSLocationInRange(targetRow, attributeValueRange)) {
            targetRow = self.currentExpandedIndexPath.row;
        } else if (targetRow > self.currentExpandedIndexPath.row) {
            targetRow -= expandedAttribute.values.count;
        }
    }

    return self.dataSource.attributes[targetRow];
}

- (BOOL)isAttributeValueAtIndexPath:(NSIndexPath*)indexPath
{
    NSParameterAssert(indexPath);

    if (self.currentExpandedIndexPath) {
        NSComparisonResult indexPathOrdering = [self.currentExpandedIndexPath compare:indexPath];
        MITMobiusAttribute *expandedAttribute = [self attributeForIndexPath:self.currentExpandedIndexPath];
        return ((indexPathOrdering == NSOrderedAscending) &&
                (self.currentExpandedIndexPath.section == indexPath.section) &&
                (indexPath.row < (self.currentExpandedIndexPath.row + expandedAttribute.values.count + 1)));
    } else {
        return NO;
    }
}

- (MITMobiusAttributeValue*)valueForIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAdvancedSearchSection section = [self _typeForSection:indexPath.section];
    NSAssert(section == MITMobiusAdvancedSearchAttributes, @"attempting to get an attribute for an invalid section");

    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];
    NSIndexPath *attributeIndexPath = [self indexPathForAttribute:attribute];
    return attribute.values[indexPath.row - attributeIndexPath.row - 1];
}

- (MITMobiusAdvancedSearchSection)_typeForSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return MITMobiusAdvancedSearchSelectedAttributes;

        default:
            return MITMobiusAdvancedSearchAttributes;
    }
}

- (NSString*)_identifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAdvancedSearchSection section = [self _typeForSection:indexPath.section];

    switch (section) {
        case MITMobiusAdvancedSearchAttributes: {
            if ([self isAttributeValueAtIndexPath:indexPath]) {
                return MITMobiusAdvancedSearchAttributeValueCellIdentifier;
            } else {
                return MITMobiusAdvancedSearchAttributeCellIdentifier;
            }
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
    if (section == 0) {
        if (self.query.text.length) {
            return self.query.options.count + 1;
        } else {
            return self.query.options.count;
        }
    } else if (section == 1) {
        if (self.currentExpandedIndexPath) {
            MITMobiusAttribute *expandedAttribute = [self attributeForIndexPath:self.currentExpandedIndexPath];
            return self.dataSource.attributes.count + expandedAttribute.values.count;
        } else {
            return self.dataSource.attributes.count;
        }
    }

    return 0;
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
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];

    if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier]) {
        NSUInteger index = indexPath.row;

        if (index == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"\"%@\"",self.query.text];
            cell.detailTextLabel.text = @"Text";
        } else {
            --index;
            MITMobiusSearchOption *option = self.query.options[index];
            cell.textLabel.text = option.value;
            cell.detailTextLabel.text = option.attribute.label;
        }
    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeCellIdentifier]) {
        MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];
        cell.textLabel.text = attribute.label;

        if ([attribute.label isEqualToString:@"Audience3"]) {
            [attribute.values enumerateObjectsUsingBlock:^(MITMobiusAttributeValue *value, NSUInteger idx, BOOL *stop) {
                DDLogVerbose(@"%ld: %@",(long)idx, value.text);
            }];
        }

        BOOL isAttributeExpanded = [indexPath isEqual:self.currentExpandedIndexPath];
        UIImage *image = nil;
        if (isAttributeExpanded) {
            image = [UIImage imageNamed:MITImageDisclosureRight];
        } else {
            image = [UIImage imageNamed:MITImageNameRightArrow];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeValueCellIdentifier]) {
        MITMobiusAttributeValue *value = [self valueForIndexPath:indexPath];
        cell.textLabel.text = value.text;
        cell.indentationLevel = 1;
    } else {
        NSString *reason = [NSString stringWithFormat:@"unknown cell reuse identifier %@",cell.reuseIdentifier];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMobiusAdvancedSearchSection sectionType = [self _typeForSection:indexPath.section];
    if (sectionType == MITMobiusAdvancedSearchAttributes) {
        if ([self isAttributeValueAtIndexPath:indexPath]) {
            MITMobiusAttributeValue *attributeValue = [self valueForIndexPath:indexPath];
            [self setAttributeValue:attributeValue];
        } else {
            [tableView beginUpdates];

            // To account for -[NSIndexPath isEqual:] not always returning true, even if it is
            indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
            MITMobiusAttribute *newAttribute = [self attributeForIndexPath:indexPath];

            if ([indexPath isEqual:self.currentExpandedIndexPath]) {
                [self _collapseItemAtIndexPath:indexPath];
                self.currentExpandedIndexPath = nil;
            } else {
                if (self.currentExpandedIndexPath) {
                    [self _collapseItemAtIndexPath:self.currentExpandedIndexPath];
                }

                NSIndexPath *newIndexPath = [self indexPathForAttribute:newAttribute];
                self.currentExpandedIndexPath = newIndexPath;
                [self _expandItemAtIndexPath:newIndexPath];
            }

            [tableView endUpdates];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setAttributeValue:(MITMobiusAttributeValue*)attributeValue
{
    NSParameterAssert(attributeValue);
    [self.query.options enumerateObjectsUsingBlock:^(MITMobiusSearchOption *option, NSUInteger idx, BOOL *stop) {
        if ([option.attribute isEqual:attributeValue.attribute]) {
            if (![option.values containsObject:attributeValue]) {
                [option removeValues:option.values];
                [option addValuesObject:attributeValue];
            }
        }
    }];
}

@end
