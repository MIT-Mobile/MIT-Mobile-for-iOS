#import <UIKit/UIKit.h>

// For use when you want only some of your tableview cells to have separators

@interface BorderedTableViewCell : UITableViewCell {
    UIView *borderView;
    CGFloat borderWidth;
}

@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, retain) UIColor *borderColor;

@end
