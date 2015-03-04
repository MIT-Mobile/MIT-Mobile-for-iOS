
#import <UIKit/UIKit.h>

@class MITSingleWebViewCellTableViewController;

@protocol MITSingleWebViewCellTableViewControllerDelegate <NSObject>

- (void)singleWebViewCellTableViewControllerDidUpdateHeight:(MITSingleWebViewCellTableViewController *)tableViewController;

@end

@interface MITSingleWebViewCellTableViewController : UITableViewController

@property (nonatomic, strong) NSString * html;          // used when you'd like to override entire webview html
@property (nonatomic, strong) NSString * htmlContent;   // used to simple add html content, not used if html is set

@property (nonatomic, assign) UIEdgeInsets webViewInsets;

@property (nonatomic, weak) id<MITSingleWebViewCellTableViewControllerDelegate> delegate;


- (CGFloat)targetTableViewHeight;

@end
