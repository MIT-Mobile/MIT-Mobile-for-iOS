#import <UIKit/UIKit.h>
#import "QRReaderScanViewController.h"

@class QRReaderHistoryData;
@class QRReaderScanViewController;
@class QRReaderHelpView;

@interface QRReaderHistoryViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,ZBarReaderDelegate,QRReaderScanDelegate> {
    UITableView *_tableView;
    UIView *_contentView;
    QRReaderHelpView *_helpView;
    QRReaderScanViewController *_scanController;
    __weak QRReaderHistoryData *_history;
    __weak UIButton *_scanButton;
}

@property (nonatomic,readonly,retain) IBOutlet UITableView *tableView;

- (IBAction)showHelp:(id)sender;
- (IBAction)hideHelp:(id)sender;
@end
