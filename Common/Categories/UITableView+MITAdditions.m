#import "UITableView+MITAdditions.h"

@implementation UITableView (MITAdditions)

- (void)reloadDataAndMaintainSelection
{
    NSIndexPath *selectedIndexPath = [self indexPathForSelectedRow];
    [self reloadData];
    if (selectedIndexPath) {
        [self selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

@end
