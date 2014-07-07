#import <UIKit/UIKit.h>

@interface MITMapPlaceBottomButtonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *button;

- (void)setTopSeparatorHidden:(BOOL)hidden;
- (void)setBottomSeparatorHidden:(BOOL)hidden;

@end
