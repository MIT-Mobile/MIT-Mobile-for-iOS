#import <UIKit/UIKit.h>

@interface BookDetailTableViewCell : UITableViewCell

@property (nonatomic, retain) NSAttributedString *displayString;

+ (NSAttributedString *)displayStringWithTitle:(NSString *)title
                                      subtitle:(NSString *)subtitle
                                     separator:(NSString *)separator;

+ (CGSize)sizeForDisplayString:(NSAttributedString *)displayString tableView:(UITableView *)tableView;

@end


typedef enum {
    TableViewCellPositionFirst = 1 << 8,
    TableViewCellPositionLast = 2 << 8
} TableViewCellPosition;

@interface LibrariesBorderedTableViewCell : UITableViewCell

@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic) TableViewCellPosition cellPosition;

@end

