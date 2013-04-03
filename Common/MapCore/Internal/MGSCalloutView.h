#import <UIKit/UIKit.h>

@interface MGSCalloutView : UIView
@property (nonatomic,assign) CGSize imageSize;
@property (nonatomic,readonly,weak) UILabel *titleLabel;
@property (nonatomic,readonly,weak) UILabel *detailLabel;
@property (nonatomic,readonly,weak) UIImageView *imageView;

@property (nonatomic,copy) void (^accessoryBlock)(id sender);
@end
