// Based on sample code from http://stackoverflow.com/questions/400965/how-to-customize-the-background-border-colors-of-a-grouped-table-view 

#import <UIKit/UIKit.h>

typedef enum  {
    TransparentGroupedTableCellViewPositionTop, 
    TransparentGroupedTableCellViewPositionMiddle, 
    TransparentGroupedTableCellViewPositionBottom,
    TransparentGroupedTableCellViewPositionSingle
} TransparentGroupedTableCellViewPosition;

@interface TransparentGroupedTableCellView : UIView {
    UIColor *borderColor;
    UIColor *fillColor;
    TransparentGroupedTableCellViewPosition position;
}

- (void)updatePositionForIndex:(NSInteger)index total:(NSInteger)total;

@property(nonatomic, retain) UIColor *borderColor, *fillColor;
@property(nonatomic) TransparentGroupedTableCellViewPosition position;
@end

