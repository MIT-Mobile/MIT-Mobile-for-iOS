#import <UIKit/UIKit.h>

@interface FacilitiesSubmitViewController : UIViewController {
    UILabel *_statusLabel;
    UIProgressView *_progressView;
    UIButton *_completeButton;
    BOOL _abortRequest;
}

@property (nonatomic,retain) IBOutlet UILabel* statusLabel;
@property (nonatomic,retain) IBOutlet UIProgressView* progressView;
@property (nonatomic,retain) IBOutlet UIButton* completeButton;

@end
