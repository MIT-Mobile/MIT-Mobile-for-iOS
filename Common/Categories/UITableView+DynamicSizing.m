#import <objc/runtime.h>
#import "UITableView+DynamicSizing.h"

static NSString* const MITNewsCachedLayoutCellsAssociatedObjectKey = @"MITNewsCachedLayoutCellsAssociatedObject";

@implementation UITableView (DynamicSizing)
- (NSMutableDictionary*)_cachedLayoutCells
{
    const void *objectKey = (__bridge const void *)MITNewsCachedLayoutCellsAssociatedObjectKey;
    NSMutableDictionary *cachedLayoutCellsByIdentifier = objc_getAssociatedObject(self,objectKey);

    if (!cachedLayoutCellsByIdentifier) {
        cachedLayoutCellsByIdentifier = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, objectKey, cachedLayoutCellsByIdentifier, OBJC_ASSOCIATION_RETAIN);
    }

    return cachedLayoutCellsByIdentifier;
}


- (void)registerClass:(Class)nilOrClass forDynamicCellReuseIdentifier:(NSString*)cellReuseIdentifier
{
    // Order is important! This depends on !nilOrClass short-circuiting the
    // OR.

    // See if something was passed in. nil is a perfectly acceptable value here
    // so the next checks will be to ensure that a) we have a class and b)
    // said class is a subclass of UITableViewCell
    if (nilOrClass) {
        if (!class_isMetaClass(object_getClass(nilOrClass))) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"%@ requires a nil or Class-type object" userInfo:nil];
        } else if (![nilOrClass isSubclassOfClass:[UITableViewCell class]]) {
            NSString *message = [NSString stringWithFormat:@"expected nilOrClass to be a subclass of %@",NSStringFromClass([UITableViewCell class])];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
        }
    }

    [self registerClass:nilOrClass forCellReuseIdentifier:cellReuseIdentifier];

    NSMutableDictionary *cachedLayoutCells = [self _cachedLayoutCells];
    if (nilOrClass) {
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            UITableViewCell *layoutCell = (UITableViewCell*)[[[nilOrClass class] alloc] init];
            cachedLayoutCells[cellReuseIdentifier] = layoutCell;
        } else {
            [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
        }
    } else {
        [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
    }
}

- (void)registerNib:(UINib*)nilOrNib forDynamicCellReuseIdentifier:(NSString*)cellReuseIdentifier
{
    NSParameterAssert(!nilOrNib || [nilOrNib isKindOfClass:[UINib class]]);

    [self registerNib:nilOrNib forCellReuseIdentifier:cellReuseIdentifier];

    NSMutableDictionary *cachedLayoutCells = [self _cachedLayoutCells];

    if (nilOrNib) {
        // If we are on iOS 6.1 or lower, manually create the cell from the nib. iOS 6 behaves
        // extremely poorly if you ask UITableView to dequeue a reusable cell and then not
        // use it for display.
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            UITableViewCell *layoutCell = [[nilOrNib instantiateWithOwner:nil options:nil] firstObject];
            NSAssert([layoutCell isKindOfClass:[UITableViewCell class]], @"class must be a subclass of %@",NSStringFromClass([UITableViewCell class]));
            cachedLayoutCells[cellReuseIdentifier] = layoutCell;
        } else {
            [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
        }
    } else {
        [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
    }
}

- (CGFloat)minimumHeightForCellWithReuseIdentifier:(NSString *)reuseIdentifier atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *layoutCell = [self _dequeueReusableLayoutCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    if (!layoutCell) {
        if (self.rowHeight != UITableViewAutomaticDimension) {
            DDLogWarn(@"failed to dequeue a layout cell, falling back to default table view row height");
            return self.rowHeight;
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"failed to dequeue a valid layout cell and table view requires an automatic dimension" userInfo:nil];
        }
    }

    if ([self.dataSource conformsToProtocol:@protocol(UITableViewDataSourceDynamicSizing)]) {
        id<UITableViewDataSourceDynamicSizing> dataSource = (id<UITableViewDataSourceDynamicSizing>)self.dataSource;
        [dataSource tableView:self configureCell:layoutCell forRowAtIndexPath:indexPath];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"failed to configure cell, %@ does not conform to <%@>",NSStringFromClass([self class]),NSStringFromProtocol(@protocol(UITableViewDataSourceDynamicSizing))]
                                     userInfo:nil];
    }

    [layoutCell setNeedsUpdateConstraints];
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];

    CGSize rowSize = [layoutCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat separatorHeight = (self.separatorStyle == UITableViewCellSeparatorStyleNone) ? 0. : 1.;
    
    return (ceil(rowSize.height) + separatorHeight);
}

- (UITableViewCell*)_dequeueReusableLayoutCellWithIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary *cachedLayoutCellsForTableView = [self _cachedLayoutCells];
    UITableViewCell *layoutCell = cachedLayoutCellsForTableView[reuseIdentifier];

    if (!layoutCell) {
        layoutCell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
        NSAssert(layoutCell, @"you must register a nib or class with for reuse identifier '%@'",reuseIdentifier);
        cachedLayoutCellsForTableView[reuseIdentifier] = layoutCell;
    }

    CGSize cellSize = [layoutCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    layoutCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    // Ensure the size is larger than the minimum so the separator doesn't cause constraints to be
    // unsatisfiable
    layoutCell.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), cellSize.height + 1.);

    if (![layoutCell isDescendantOfView:self]) {
        [self addSubview:layoutCell];
    } else {
        [layoutCell prepareForReuse];
    }

    // prepareForReuse likes to force this to be 'NO'
    layoutCell.hidden = YES;
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];

    return layoutCell;
}

@end
