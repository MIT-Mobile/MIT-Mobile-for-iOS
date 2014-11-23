//
//  MITScannerDetailViewController.h
//  MIT Mobile
//
//  Created by Yev Motov on 11/16/14.
//
//

#import <UIKit/UIKit.h>

@class QRReaderResult;

@interface MITScannerDetailViewController : UIViewController

@property (nonatomic, strong) QRReaderResult *scanResult;

@end
