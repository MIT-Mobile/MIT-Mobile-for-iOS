#import <UIKit/UIKit.h>

@interface BookDetailTableViewCell : UITableViewCell

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *separator;

@property (nonatomic, retain) NSAttributedString *displayString;

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

