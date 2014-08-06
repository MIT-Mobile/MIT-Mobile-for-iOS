
#import <UIKit/UIKit.h>

@interface MITDateNavigationBarView : UIView

@property (weak, nonatomic) IBOutlet UILabel *currentDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *previousDateButton;
@property (weak, nonatomic) IBOutlet UIButton *nextDateButton;
@property (weak, nonatomic) IBOutlet UIButton *showDateControlButton;

@end
