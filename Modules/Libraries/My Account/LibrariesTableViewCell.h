#import <UIKit/UIKit.h>

@interface LibrariesTableViewCell : UITableViewCell
@property (nonatomic,copy) NSDictionary *itemDetails;
@property (nonatomic,retain) UILabel *titleLabel;
@property (nonatomic,retain) UILabel *infoLabel;
@property (nonatomic,retain) UILabel *statusLabel;
@property (nonatomic,retain) UIImageView *statusIcon;
@property (nonatomic,assign) UIEdgeInsets contentViewInsets;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

- (void)layoutContentUsingBounds:(CGRect)bounds;
- (CGSize)contentSizeThatFits:(CGSize)size;
@end
