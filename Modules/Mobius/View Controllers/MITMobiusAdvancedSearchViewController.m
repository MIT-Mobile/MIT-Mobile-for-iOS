#import "MITMobiusAdvancedSearchViewController.h"

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
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _searchText = [searchText copy];
    }

    return self;
}

#pragma mark Data Updating
- (void)_reloadAttributes:(


#pragma mark DataSource helper methods


#pragma mark UITableViewDelegate


#pragma mark UITableViewDataSource


@end
