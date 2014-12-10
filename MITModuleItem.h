#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITModulePresentationStyle) {
    MITModulePresentationFullScreen = 0,
    MITModulePresentationModal
};

@interface MITModuleItem : NSObject
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIImage *selectedImage;

@property(nonatomic,copy) NSString *badgeValue;
@property(nonatomic) MITModulePresentationStyle type;

- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image;
- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage;
@end

@interface UIViewController (MITModuleItem)
@property(nonatomic,strong) MITModuleItem *moduleItem;
@end