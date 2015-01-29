#import <UIKit/UIKit.h>

@interface MITAutoSizingCell : UITableViewCell

+ (CGFloat)heightForContent:(id)content
             tableViewWidth:(CGFloat)width;

// The following must be implemented in a subclass:
+ (CGFloat)estimatedCellHeight;
- (void)setContent:(id)content;

@end
