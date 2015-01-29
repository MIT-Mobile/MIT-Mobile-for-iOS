#import "MITAutoSizingCell.h"

@implementation MITAutoSizingCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    for (UIView *view in self.contentView.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).preferredMaxLayoutWidth = view.frame.size.width;
        }
    }
}

// This must be implemented in a subclass
- (void)setContent:(id)content
{
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForContent:(id)content
             tableViewWidth:(CGFloat)width
{
    [[self sizingCell] setContent:content];
    return [self heightForCell:[self sizingCell] tableWidth:width];
}

+ (CGFloat)heightForCell:(MITAutoSizingCell *)cell tableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    // Call again to force proper layout -- otherwise, on iOS 7 some cells size improperly.  If target == iOS 8.0+ you can remove this
    [cell layoutIfNeeded];
    [cell refreshLabelLayoutWidths];
    //
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX([self estimatedCellHeight], height);
}

+ (MITAutoSizingCell *)sizingCell
{
    static NSMutableDictionary *sizingCellDictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCellDictionary = [NSMutableDictionary dictionary];
    });
    
    NSString *classCellKey = NSStringFromClass([self class]);
    MITAutoSizingCell *sizingCell = [sizingCellDictionary objectForKey:classCellKey];
    if (!sizingCell) {
        UINib *numberedResultCellNib = [UINib nibWithNibName:classCellKey bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
        [sizingCellDictionary setObject:sizingCell forKey:classCellKey];
    }
    
    return sizingCell;
}

// This should be subclassed if you want a different default height
+ (CGFloat)estimatedCellHeight
{
    return 44.0;
}

@end
