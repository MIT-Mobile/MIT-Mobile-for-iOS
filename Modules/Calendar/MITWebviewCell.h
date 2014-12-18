#import <UIKit/UIKit.h>

@protocol MITWebviewCellDelegate;

@interface MITWebviewCell : UITableViewCell

@property (nonatomic, weak) id<MITWebviewCellDelegate> delegate;

@property (nonatomic, strong) NSString *htmlString;
- (void)setHtmlString:(NSString *)htmlString forceUpdate:(BOOL)forceUpdate;

@end

@protocol MITWebviewCellDelegate <NSObject>

- (void)webviewCellDidResize:(MITWebviewCell *)webviewCell toHeight:(CGFloat)newHeight;

@end