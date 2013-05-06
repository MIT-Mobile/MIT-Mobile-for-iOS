#import <UIKit/UIKit.h>

@interface DiningLocationCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, assign) BOOL statusOpen;
@property (nonatomic, readonly, strong) UILabel * titleLabel;
@property (nonatomic, readonly, strong) UILabel * subtitleLabel;

+ (CGFloat) heightForRowWithTitle:(NSString *)title subtitle:(NSString *) subtitle;

@end
