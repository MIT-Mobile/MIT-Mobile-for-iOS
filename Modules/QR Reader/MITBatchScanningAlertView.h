//
//  MITBatchScanningAlertView.h
//  MIT Mobile
//
//  Created by Yev Motov on 12/6/14.
//
//

#import <UIKit/UIKit.h>

@interface MITBatchScanningAlertView : UIView

@property (weak, nonatomic) IBOutlet UILabel *scanCodeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ScanThumbnailView;

- (void)fadeOutWithDuration:(NSTimeInterval)duration andWait:(NSTimeInterval)wait;

@end
