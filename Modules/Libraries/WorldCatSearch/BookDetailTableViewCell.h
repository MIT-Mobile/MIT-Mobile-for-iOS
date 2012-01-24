#import <UIKit/UIKit.h>

const CGFloat BookDetailFontSizeTitle;
const CGFloat BookDetailFontSizeDefault;

@interface BookDetailTableViewCell : UITableViewCell

@property (nonatomic, retain) NSAttributedString *displayString;

+ (NSAttributedString *)displayStringWithTitle:(NSString *)title
                                      subtitle:(NSString *)subtitle
                                     separator:(NSString *)separator
                                      fontSize:(CGFloat)fontSize;

+ (CGSize)sizeForDisplayString:(NSAttributedString *)displayString tableView:(UITableView *)tableView;

@end
