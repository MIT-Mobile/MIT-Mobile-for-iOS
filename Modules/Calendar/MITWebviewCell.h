#import <UIKit/UIKit.h>

@protocol MITWebviewCellDelegate;

@interface MITWebviewCell : UITableViewCell

@property (nonatomic, weak) id<MITWebviewCellDelegate> delegate;

- (void)setHTMLString:(NSString *)htmlString;

@end

@protocol MITWebviewCellDelegate <NSObject>

- (void)webviewCellDidResize:(MITWebviewCell *)webviewCell;

@end