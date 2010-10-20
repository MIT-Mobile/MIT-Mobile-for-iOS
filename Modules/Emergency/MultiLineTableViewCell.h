#import <UIKit/UIKit.h>


@interface MultiLineTableViewCell : UITableViewCell {
	CGFloat topPadding;
	CGFloat bottomPadding;

}
@property CGFloat topPadding;
@property CGFloat bottomPadding;

- (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height;

+ (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height topPadding: (CGFloat)topPadding;

+ (CGFloat) defaultTopPadding;

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
+ (CGFloat) widthAdjustmentForAccessoryType: (UITableViewCellAccessoryType)accessoryType isGrouped: (BOOL)isGrouped;

@end

