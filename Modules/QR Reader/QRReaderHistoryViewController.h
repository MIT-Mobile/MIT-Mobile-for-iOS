//
//  QRReaderHistoryViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/6/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QRReaderScanViewController.h"

@class QRReaderHistoryData;
@class QRReaderScanViewController;
@class QRReaderHelpView;

@interface QRReaderHistoryViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,QRReaderScanDelegate> {
    UITableView *_tableView;
    UIToolbar *_toolbar;
    UIView *_contentView;
    QRReaderHelpView *_helpView;
    QRReaderScanViewController *_scanController;
    __weak QRReaderHistoryData *_history;
    __weak UIButton *_scanButton;
}

@property (nonatomic,readonly,retain) IBOutlet UITableView *tableView;
@property (nonatomic,readonly,retain) IBOutlet UIToolbar *toolbar;

- (IBAction)showHelp:(id)sender;
- (IBAction)hideHelp:(id)sender;
@end
