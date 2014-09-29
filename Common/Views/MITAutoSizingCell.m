#import "MITAutoSizingCell.h"

@implementation MITAutoSizingCell

- (void)awakeFromNib
{
    [self recursivelyRefreshLabelLayoutWidthsInView:self];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self recursivelyRefreshLabelLayoutWidthsInView:self];
}

- (void)recursivelyRefreshLabelLayoutWidthsInView:(UIView *)view
{
    if ([view isKindOfClass:[UILabel class]]) {
        ((UILabel *)view).preferredMaxLayoutWidth = view.frame.size.width;
    }
    
    if (view.subviews.count > 0) {
        for (UIView *subview in view.subviews) {
            [self recursivelyRefreshLabelLayoutWidthsInView:subview];
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
    return [self heightForCell:[self sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITAutoSizingCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX([self estimatedCellHeight], height);
}

+ (MITAutoSizingCell *)sizingCell
{
//    This function must be subclassed, your subclass will usually have something like this in it:
//    
//    static MITAutoSizingCell *sizingCell;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
//        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
//    });
//    return sizingCell;

    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// This should be subclassed if you want a different default height
+ (CGFloat)estimatedCellHeight
{
    return 44.0;
}

@end
