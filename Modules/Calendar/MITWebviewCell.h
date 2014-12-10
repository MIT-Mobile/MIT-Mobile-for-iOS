#import <UIKit/UIKit.h>

@protocol MITWebviewCellDelegate;

@interface MITWebviewCell : UITableViewCell

@property (nonatomic, weak) id<MITWebviewCellDelegate> delegate;

@property (nonatomic, strong) NSString *htmlString;

@end

@protocol MITWebviewCellDelegate <NSObject>

- (void)webviewCellDidResize:(MITWebviewCell *)webviewCell toHeight:(CGFloat)newHeight;

@end