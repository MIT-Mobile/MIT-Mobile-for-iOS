//
//  MITScannerDetailViewController.h
//  MIT Mobile
//
//  Created by Yev Motov on 11/16/14.
//
//

#import <UIKit/UIKit.h>

@class QRReaderResult;

@protocol MITScannerDetailViewControllerDelegate
- (void)detailFormSheetViewDidDisappear;
@end

@interface MITScannerDetailViewController : UIViewController

@property (nonatomic, strong) QRReaderResult *scanResult;

@property (nonatomic, weak) id <MITScannerDetailViewControllerDelegate> delegate;

@end
