#import <UIKit/UIKit.h>

extern const CGFloat kLibrariesTableCellDefaultWidth;

@interface LibrariesTableViewCell : UITableViewCell
@property (nonatomic,copy) NSDictionary *itemDetails;
@property (nonatomic,retain) UILabel *titleLabel;
@property (nonatomic,retain) UILabel *infoLabel;
@property (nonatomic,retain) UILabel *statusLabel;
@property (nonatomic,retain) UIImageView *statusIcon;
@property (nonatomic,assign) UIEdgeInsets contentViewInsets;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)layoutContentUsingBounds:(CGRect)bounds;
- (CGFloat)heightForContentWithWidth:(CGFloat)width;
@end
