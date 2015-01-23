#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class MITBatchScanningAlertView;

@protocol MITBatchScanningAlertViewDelegate <NSObject>

- (void)didTouchAlertView:(MITBatchScanningAlertView *)alertView;

@end

@interface MITBatchScanningAlertView : UIView

@property (weak, nonatomic) IBOutlet UILabel *scanCodeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ScanThumbnailView;

@property (strong, nonatomic) NSManagedObjectID *scanId;

@property (weak, nonatomic) id<MITBatchScanningAlertViewDelegate> delegate;

- (void)fadeOutWithDuration:(NSTimeInterval)duration
                    andWait:(NSTimeInterval)wait
                 completion:(void (^)(void))completionBlock;

@end
