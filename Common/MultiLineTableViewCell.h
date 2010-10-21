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

/*
// various methods to calculate cell height
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
							detail: (NSString *)detail
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped;

// this method allows you to customize the fonts
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail 
						detailFont: (UIFont *)detailFont
					 accessoryType: (UITableViewCellAccessoryType)accessoryType 
						 isGrouped: (BOOL)isGrouped;

// this method allows you to customize the horizontal width constraint
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
							detail: (NSString *)detail 
				   widthAdjustment: (CGFloat)widthAdjustment;

// this method allows you customize the top vertical padding
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
							detail: (NSString *)detail 
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped
						topPadding: (CGFloat)topPadding;

// this method allows you to customize the horizontal constraints and vertical padding
+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail
						detailFont: (UIFont *)detailFont
				   widthAdjustment: (CGFloat)widthAdjustment
						topPadding: (CGFloat)topPadding
					 bottomPadding: (CGFloat)bottomPadding;

// this method is used to calculate the horizontal constraint
//+ (CGFloat) widthAdjustmentForAccessoryType: (UITableViewCellAccessoryType)accessoryType isGrouped: (BOOL)isGrouped;
*/
@end

