#import <UIKit/UIKit.h>
#import "MITUIConstants.h"

@interface MultiLineTableViewCell : UITableViewCell {
	CGFloat topPadding;
	CGFloat bottomPadding;

    UILineBreakMode textLabelLineBreakMode;
    NSInteger textLabelNumberOfLines;
    
    UILineBreakMode detailTextLabelLineBreakMode;
    NSInteger detailTextLabelNumberOfLines;
}

@property CGFloat topPadding;
@property CGFloat bottomPadding;

@property UILineBreakMode textLabelLineBreakMode;
@property NSInteger textLabelNumberOfLines;

@property UILineBreakMode detailTextLabelLineBreakMode;
@property NSInteger detailTextLabelNumberOfLines;

- (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height;

+ (CGFloat *)cellWidthForTableStyle:(UITableViewStyle)style accessoryType:(UITableViewCellAccessoryType)accessoryType;

// the argument for accessoryType MUST match the accessory type of the cell that is going to be laid out.
// otherwise the app may go into an infinite loop.
+ (CGFloat)cellHeightForTableView:(UITableView *)tableView
                             text:(NSString *)text
                       detailText:(NSString *)detailText
                    accessoryType:(UITableViewCellAccessoryType)accessoryType;

+ (CGFloat)cellHeightForTableView:(UITableView *)tableView
                             text:(NSString *)text
                       detailText:(NSString *)detailText
                         textFont:(UIFont *)textFont
                       detailFont:(UIFont *)detailFont
                    accessoryType:(UITableViewCellAccessoryType)accessoryType;

+ (void)setNeedsRedrawing:(BOOL)needsRedrawing;
+ (BOOL)needsRedrawing;
@end

