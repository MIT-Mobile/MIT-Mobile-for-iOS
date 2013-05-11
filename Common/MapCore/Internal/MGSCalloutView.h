#import <UIKit/UIKit.h>

@interface MGSCalloutView : UIView
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *detail;
@property (nonatomic,strong) UIImage *image;

@property (nonatomic,copy) void (^accessoryActionBlock)(id sender);

- (id)init;
- (id)initWithFrame:(CGRect)frame;
- (id)initWithCoder:(NSCoder *)aDecoder;
@end
