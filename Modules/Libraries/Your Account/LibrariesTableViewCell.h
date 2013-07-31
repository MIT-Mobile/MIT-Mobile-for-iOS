#import <UIKit/UIKit.h>

extern const CGFloat kLibrariesTableCellDefaultWidth;

@interface LibrariesTableViewCell : UITableViewCell
@property (nonatomic,weak) UILabel *titleLabel;
@property (nonatomic,weak) UILabel *infoLabel;
@property (nonatomic,weak) UILabel *statusLabel;
@property (nonatomic,weak) UIImageView *statusIcon;
@property UIEdgeInsets contentViewInsets;
@property (nonatomic,copy) NSDictionary *itemDetails;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)layoutContentUsingBounds:(CGRect)bounds;
- (CGFloat)heightForContentWithWidth:(CGFloat)width;
@end
