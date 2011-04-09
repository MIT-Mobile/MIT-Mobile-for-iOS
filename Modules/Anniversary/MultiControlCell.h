#import <UIKit/UIKit.h>


@interface MultiControlCell : UITableViewCell {
    NSArray *controls; // controls to be fit into this one cell
    CGFloat horizontalSpacing; // padding between controls inside of this cell
    CGSize margins; // padding on sides of cell
    NSInteger position; // which row this is (only matters if it's the first row)
}

@property (nonatomic, retain) NSArray *controls;
@property (nonatomic, assign) CGFloat horizontalSpacing;
@property (nonatomic, assign) CGSize margins;
@property (nonatomic, assign) NSInteger position;

@end
