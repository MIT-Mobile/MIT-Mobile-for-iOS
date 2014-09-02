#import <objc/runtime.h>
#import "UIViewController+MITDrawerNavigation.h"

NSString* const MITDrawerItemObjectKey = @"MITDrawerNavigationItemAssociatedObjectKey";

@implementation UIViewController (MITDrawerNavigation)
- (MITDrawerItem*)drawerItem
{
    id object = objc_getAssociatedObject(self, (__bridge void* const)MITDrawerItemObjectKey);

    if ([object isKindOfClass:[MITDrawerItem class]]) {
        return (MITDrawerItem*)object;
    } else {
        return nil;
    }
}

- (void)setDrawerItem:(MITDrawerItem*)drawerItem
{
    objc_setAssociatedObject(self, (__bridge void* const)MITDrawerItemObjectKey, drawerItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mit_canHandleNotification:(MITNotification*)notification
{
    return NO;
}

- (BOOL)mit_handleNotification:(MITNotification*)notification
{
    return NO;
}

- (BOOL)mit_canHandleURL:(NSURL*)url
{
    return NO;
}

- (BOOL)mit_handleURL:(NSURL*)url
{
    return NO;
}

@end

@interface MITDrawerItem ()
@property(nonatomic) NSInteger tag;
@property(nonatomic,strong) UIImage *image;
@end

@implementation MITDrawerItem
@synthesize tag = _tag;
@synthesize image = _image;
@synthesize title = _title;

- (instancetype)initWithTitle:(NSString*)title image:(UIImage*)image
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _tag = [_title hash];
        _image = image;
    }

    return self;
}

- (instancetype)initWithTitle:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _selectedImage = selectedImage;
        _tag = [_title hash];
        _image = image;
    }

    return self;
}

- (UIImage*)selectedImage
{
    if (!_selectedImage) {
        return self.image;
    } else {
        return _selectedImage;
    }
}

@end