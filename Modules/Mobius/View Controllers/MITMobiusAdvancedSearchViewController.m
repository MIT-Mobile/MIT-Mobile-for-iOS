#import "MITMobiusAdvancedSearchViewController.h"
#import "MITMobiusAttributesDataSource.h"
#import "MITMobiusModel.h"
#import "MITAdditions.h"
#import "MITMobiusAdvancedSearchSelectedAttributeCell.h"

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
@property (nonatomic,readonly,strong) NSIndexPath *currentExpandedIndexPath;
@property (nonatomic,weak) MITMobiusAttribute *currentSelectedAttribute;
@end

@implementation MITMobiusAdvancedSearchViewController {
    NSMapTable *_buttonToSearchOptionTable;
}

- (instancetype)init
{
    self = [self initWithQuery:nil];

    if (self) {

    }

    return self;
}

- (instancetype)initWithString:(NSString*)queryString
{
    self = [self initWithQuery:nil];

    if (self) {
        if (queryString.length) {
            _query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext insertNewObjectForEntityForName:[MITMobiusRecentSearchQuery entityName]];
            _query.text = queryString;
        }
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
        _buttonToSearchOptionTable = [NSMapTable weakToWeakObjectsMapTable];

        if (query) {
            _query = (MITMobiusRecentSearchQuery*)[_managedObjectContext existingObjectWithID:query.objectID error:nil];
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MITMobiusAdvancedSearchAttributeValueCellIdentifier];

    UINib *nib = [UINib nibWithNibName:NSStringFromClass([MITMobiusAdvancedSearchSelectedAttributeCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.navigationController) {
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelButtonWasTapped:)];
        UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStyleDone target:self action:@selector(_doneButtonWasTapped:)];

        [self.navigationItem setLeftBarButtonItem:cancelBarButtonItem animated:animated];
        [self.navigationItem setRightBarButtonItem:doneBarButtonItem animated:animated];

        self.navigationItem.title = @"Advanced Search";
    }

    if (!self.query) {
        self.query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext insertNewObjectForEntityForName:[MITMobiusRecentSearchQuery entityName]];
    }

    [self.dataSource attributes:^(MITMobiusAttributesDataSource *dataSource, NSError *error) {
        [self.tableView reloadData];
    }];


    [self _updateNavigationBarState:animated];
}

#pragma mark Interface Actions
- (IBAction)_cancelButtonWasTapped:(UIBarButtonItem*)sender
{
    [self.delegate advancedSearchViewControllerDidCancelSearch:self];
}

- (IBAction)_doneButtonWasTapped:(UIBarButtonItem*)sender
{
    if (self.managedObjectContext.hasChanges) {
        [self.managedObjectContext saveToPersistentStore:nil];
    }

    [self.delegate didDismissAdvancedSearchViewController:self];
}

- (NSIndexPath*)currentExpandedIndexPath
{
    return [self indexPathForAttribute:self.currentSelectedAttribute];
}

#pragma mark Data Updating
- (void)_updateNavigationBarState:(BOOL)animated
{
    if (self.query.text.length > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else if ([self numberOfSearchOptions] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)_collapseItemAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];

    NSMutableArray *deletionIndexPaths = [[NSMutableArray alloc] init];
    NSRange deletionRange = NSMakeRange(indexPath.row + 1, attribute.values.count);
    NSIndexSet *deletionIndexSet = [NSIndexSet indexSetWithIndexesInRange:deletionRange];
    [deletionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [deletionIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:indexPath.section]];
    }];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView deleteRowsAtIndexPaths:deletionIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)_expandItemAtIndexPath:(NSIndexPath*)indexPath
{
    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];

    NSInteger rowOffset = 0;
    if (indexPath.row > self.currentExpandedIndexPath.row) {
        rowOffset = self.currentSelectedAttribute.values.count;
    }

    NSMutableArray *insertionIndexPaths = [[NSMutableArray alloc] init];
    NSRange insertionRange = NSMakeRange(indexPath.row - rowOffset + 1, attribute.values.count);
    NSIndexSet *insertionIndexSet = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
    [insertionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [insertionIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:indexPath.section]];
    }];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:insertionIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
}

#pragma mark table helper methods
- (NSIndexPath*)indexPathForAttribute:(MITMobiusAttribute*)attribute
{
    if (!attribute) {
        return nil;
    }
    
    NSUInteger attributesSection = 1;
    NSUInteger indexOfAttribute = [[self attributes] indexOfObject:attribute];
    NSAssert(indexOfAttribute != NSNotFound,@"attribute %@ was not found",attribute.label);

    if (self.currentSelectedAttribute) {
        NSInteger expandedAttributeIndex = [[self attributes] indexOfObject:self.currentSelectedAttribute];

        if (expandedAttributeIndex < indexOfAttribute) {
            NSUInteger row = indexOfAttribute + self.currentSelectedAttribute.values.count;
            return [NSIndexPath indexPathForRow:row inSection:attributesSection];
        }
    }

    return [NSIndexPath indexPathForRow:indexOfAttribute inSection:attributesSection];
}

- (NSArray*)attributes
{
    NSArray *attributes = self.dataSource.attributes;

    NSPredicate *hasOneOrMoreValuesPredicate = [NSPredicate predicateWithFormat:@"values.@count > 0"];
    NSArray *attributeIdentifierWhitelist = @[@"5475e4979147112657976a4d",@"5475e4979147112657976a4e"];
    NSPredicate *whitelistedAttributes = [NSPredicate predicateWithFormat:@"identifier IN %@",attributeIdentifierWhitelist];

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[whitelistedAttributes,hasOneOrMoreValuesPredicate]];
    NSArray *filteredAttributes = [attributes filteredArrayUsingPredicate:predicate];

    return [filteredAttributes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES]]];
}

- (NSInteger)numberOfAttributes
{
    return [self attributes].count;
}

- (MITMobiusAttribute*)attributeForIndexPath:(NSIndexPath*)indexPath
{
    NSAssert(indexPath.section == MITMobiusAdvancedSearchAttributes, @"attempting to get an attribute for an invalid section");

    NSArray *attributes = [self attributes];
    NSUInteger targetRow = indexPath.row;

    if (self.currentSelectedAttribute) {
        NSInteger index = [[self attributes] indexOfObject:self.currentSelectedAttribute];
        if (index < targetRow) {
            NSInteger numberOfValues = self.currentSelectedAttribute.values.count;
            if (targetRow <= (index + numberOfValues)) {
                return self.currentSelectedAttribute;
            } else {
                targetRow -= numberOfValues;
            }
        }
    }

    return attributes[targetRow];
}

- (BOOL)isAttributeValueAtIndexPath:(NSIndexPath*)indexPath
{
    NSParameterAssert(indexPath);

    if (self.currentExpandedIndexPath) {
        MITMobiusAttributeValue *value = [self valueForIndexPath:indexPath];
        
        if (value) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (MITMobiusAttributeValue*)valueForIndexPath:(NSIndexPath*)indexPath
{
    NSAssert(indexPath.section == MITMobiusAdvancedSearchAttributes, @"attempting to get an attribute for an invalid section");

    MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];
    NSIndexPath *attributeIndexPath = [self indexPathForAttribute:attribute];

    // If we are tapping the attribute name (and not one of the values, we are
    // obviously not where we should be and need to bail
    if ([indexPath isEqual:attributeIndexPath]) {
        return nil;
    } else if ([self.currentExpandedIndexPath isEqual:attributeIndexPath]) {
        if (attribute.type == MITMobiusAttributeTypeNumeric) {
            return nil;
        } else if (attribute.type == MITMobiusAttributeTypeString) {
            return nil;
        } else if (attribute.type == MITMobiusAttributeTypeText) {
            return nil;
        } else {
            return attribute.values[indexPath.row - attributeIndexPath.row - 1];
        }
    } else {
        return nil;
    }
}

- (NSString*)_identifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch (indexPath.section) {
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

        default:
            return nil;
    }
}

#pragma mark Actions
- (IBAction)attributeClearButtonWasTapped:(UIButton*)sender
{
    UITableViewCell *cell = [_buttonToSearchOptionTable objectForKey:sender];
    if (!cell) {
        return;
    }

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }

    NSUInteger row = indexPath.row;
    if ([self hasFreeText] && (row == 0)) {
        self.query.text = nil;
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:MITMobiusAdvancedSearchSelectedAttributes]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        MITMobiusSearchOption *searchOption = [self searchOptionAtIndexPath:indexPath];

        [self.tableView beginUpdates];
        [self unsetAttributeValues:[searchOption.values array]];
        [self.tableView endUpdates];
    }

    [self _updateNavigationBarState:YES];
}

- (BOOL)hasFreeText
{
    return (self.query.text.length > 0);
}

- (NSArray*)searchOptions
{
    return [[self.query.options array] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"values.@count > 0"]];
}

- (NSInteger)numberOfSearchOptions
{
    if ([self hasFreeText]) {
        return [self searchOptions].count  + 1;
    } else {
        return [self searchOptions].count;
    }
}

- (MITMobiusSearchOption*)searchOptionAtIndexPath:(NSIndexPath*)indexPath
{
    NSAssert(indexPath.section == MITMobiusAdvancedSearchSelectedAttributes,@"search options are only valid in the selected attributes value");

    NSInteger index = indexPath.row;
    if ([self hasFreeText]) {
        --index;
    }

    return [self searchOptions][index];
}

#pragma mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self numberOfSearchOptions];
    } else if (section == 1) {
        return [self numberOfAttributes] + self.currentSelectedAttribute.values.count;
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
    if (indexPath.section == 0) {
        return 54.;
    } else {
        return 44.;
    }
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];

    if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchSelectedAttributeCellIdentifier]) {
        NSUInteger index = indexPath.row;

        if (index == 0 && [self hasFreeText]) {
            cell.textLabel.text = @"Text";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"\"%@\"",self.query.text];
        } else {
            MITMobiusSearchOption *option = [self searchOptionAtIndexPath:indexPath];
            cell.textLabel.text = option.attribute.label;
            cell.detailTextLabel.text = option.value;
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:@"Clear" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(attributeClearButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        cell.accessoryView = button;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [_buttonToSearchOptionTable setObject:cell forKey:button];
    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeCellIdentifier]) {
        MITMobiusAttribute *attribute = [self attributeForIndexPath:indexPath];
        cell.textLabel.text = attribute.label;

        BOOL isAttributeExpanded = [indexPath isEqual:self.currentExpandedIndexPath];
        UIImage *image = nil;
        if (isAttributeExpanded) {
            image = [UIImage imageNamed:MITImageMobiusAccordionOpened];
        } else {
            image = [UIImage imageNamed:MITImageMobiusAccordionClosed];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
    } else if ([cell.reuseIdentifier isEqualToString:MITMobiusAdvancedSearchAttributeValueCellIdentifier]) {
        MITMobiusAttributeValue *value = [self valueForIndexPath:indexPath];
        cell.textLabel.text = value.text;
        cell.indentationLevel = 2;

        if ([self isAttributeValueSelected:value]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        NSString *reason = [NSString stringWithFormat:@"unknown cell reuse identifier %@",cell.reuseIdentifier];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITMobiusAdvancedSearchAttributes: {
            [tableView beginUpdates];

            if ([self isAttributeValueAtIndexPath:indexPath]) {
                MITMobiusAttributeValue *attributeValue = [self valueForIndexPath:indexPath];

                if (![self isAttributeValueSelected:attributeValue]) {
                    [self setAttributeValue:attributeValue];
                } else {
                    [self unsetAttributeValues:@[attributeValue]];
                }
            } else {
                // To account for -[NSIndexPath isEqual:] not always returning true, even if it is
                indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
                MITMobiusAttribute *newAttribute = [self attributeForIndexPath:indexPath];

                if ([newAttribute isEqual:self.currentSelectedAttribute]) {
                    [self _collapseItemAtIndexPath:indexPath];
                    self.currentSelectedAttribute = nil;
                } else {
                    if (self.currentSelectedAttribute) {
                        [self _collapseItemAtIndexPath:self.currentExpandedIndexPath];
                    }

                    [self _expandItemAtIndexPath:indexPath];
                    self.currentSelectedAttribute = newAttribute;
                }
            }
            
            [tableView endUpdates];
        } break;

        default: {
            /* Do Nothing*/
        } break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case MITMobiusAdvancedSearchSelectedAttributes: {
            if (self.query.options.count == 0) {
                return @"Select one or more criteria to narrow search results.";
            } else {
                return nil;
            }
        }

        default:
            return nil;
    }
}

- (void)unsetAttributeValues:(NSArray*)attributeValues
{
    NSParameterAssert(attributeValues);

    if (attributeValues.count == 0) {
        return;
    }

    NSMutableArray *updatedIndexPaths = [[NSMutableArray alloc] init];
    NSArray *queryOptions = [self searchOptions];

    [attributeValues enumerateObjectsUsingBlock:^(MITMobiusAttributeValue *value, NSUInteger idx, BOOL *stop) {
        MITMobiusAttributeType type = value.attribute.type;

        BOOL isAttributeOptionType = (type == MITMobiusAttributeTypeOptionSingle |
                                      type == MITMobiusAttributeTypeAutocompletion |
                                      type == MITMobiusAttributeTypeOptionMultiple);
        NSAssert(isAttributeOptionType, @"attempting to clear attribute value on an attribute which should not have a valueset");

        __block MITMobiusSearchOption *searchOption = nil;
        [queryOptions enumerateObjectsUsingBlock:^(MITMobiusSearchOption *option, NSUInteger idx, BOOL *stop) {
            if ([option.attribute isEqual:value.attribute]) {
                searchOption = option;
                (*stop) = YES;
            }
        }];


        NSMutableOrderedSet *values = [searchOption mutableOrderedSetValueForKey:@"values"];
        [values removeObject:value];

        if (values.count == 0) {
            [self.managedObjectContext deleteObject:searchOption];
        }

        NSIndexPath *attributeIndexPath = [self indexPathForAttribute:value.attribute];
        if ([self.currentExpandedIndexPath isEqual:attributeIndexPath]) {
            NSInteger valueIndex = [value.attribute.values indexOfObject:value] + attributeIndexPath.row + 1;
            NSIndexPath *valueIndexPath = [NSIndexPath indexPathForRow:valueIndex inSection:attributeIndexPath.section];
            [updatedIndexPaths addObject:valueIndexPath];
        }
    }];


    [self.managedObjectContext processPendingChanges];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITMobiusAdvancedSearchSelectedAttributes] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:updatedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    [self _updateNavigationBarState:NO];
}

- (void)setAttributeValue:(MITMobiusAttributeValue*)attributeValue
{
    NSParameterAssert(attributeValue);

    MITMobiusAttributeType type = attributeValue.attribute.type;
    BOOL isAttributeOptionType = (type == MITMobiusAttributeTypeOptionSingle |
                                        type == MITMobiusAttributeTypeAutocompletion |
                                        type == MITMobiusAttributeTypeOptionMultiple);
    NSAssert(isAttributeOptionType, @"attempting to set attribute value on an attribute which should not have a valueset");

    // Sort through all the set options for the query and look for one
    // that matches the attribute of the current value we are looking for
    __block MITMobiusSearchOption *searchOption = nil;
    [self.query.options enumerateObjectsUsingBlock:^(MITMobiusSearchOption *option, NSUInteger idx, BOOL *stop) {
        if ([option.attribute isEqual:attributeValue.attribute]) {
            searchOption = option;
            (*stop) = YES;
        }
    }];

    // If a matching search option was not found in the query, create a new object and set it
    // up. Search objects should either have one or more attribute values or an attribute and a (string) value
    if (!searchOption) {
        searchOption = (MITMobiusSearchOption*)[self.managedObjectContext insertNewObjectForEntityForName:[MITMobiusSearchOption entityName]];
        searchOption.attribute = attributeValue.attribute;
        searchOption.query = self.query;
    }

    // Is the type is a single option, we should be using radio-styled selection
    // (so only a single option should be present, all others should be ignored)
    if (type == MITMobiusAttributeTypeOptionSingle) {
        [self unsetAttributeValues:[searchOption.values array]];
    }

    NSMutableOrderedSet *values = [searchOption mutableOrderedSetValueForKey:@"values"];
    [values addObject:attributeValue];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITMobiusAdvancedSearchSelectedAttributes] withRowAnimation:UITableViewRowAnimationAutomatic];

    NSIndexPath *attributeIndexPath = [self indexPathForAttribute:attributeValue.attribute];
    if ([self.currentExpandedIndexPath isEqual:attributeIndexPath]) {
        NSMutableArray *updatedIndexPaths = [[NSMutableArray alloc] init];
        for (int idx = 1; idx < attributeValue.attribute.values.count; ++idx) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(attributeIndexPath.row + idx) inSection:attributeIndexPath.section];
            [updatedIndexPaths addObject:indexPath];
        }

        [self.tableView reloadRowsAtIndexPaths:updatedIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    }

    [self _updateNavigationBarState:NO];
}

- (BOOL)isAttributeValueSelected:(MITMobiusAttributeValue*)value
{
    __block BOOL result = NO;

    [self.query.options enumerateObjectsUsingBlock:^(MITMobiusSearchOption *option, NSUInteger idx, BOOL *stop) {
        if ([option.attribute isEqual:value.attribute]) {
            result = [option.values containsObject:value];
            (*stop) = result;
        }
    }];

    return result;
}

@end
