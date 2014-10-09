#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MITModuleItem : NSObject
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,strong) UIImage *image;

@property(nonatomic,copy) NSString *badgeValue;

@property(nonatomic,copy) NSString *longTitle;
@property(nonatomic,strong) UIImage *selectedImage;

- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image;
- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage;
@end

@interface UIViewController (MITModuleItem)
@property(nonatomic,strong) MITModuleItem *moduleItem;
@end