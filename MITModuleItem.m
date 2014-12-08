#import <objc/runtime.h>
#import "MITModuleItem.h"

@implementation MITModuleItem
- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image
{
    self = [super init];
    
    if (self) {
        _title = [title copy];
        _name = [name copy];
        _image = image;
        _type = MITModulePresentationFullScreen;
    }

    return self;
}

- (instancetype)initWithName:(NSString*)name title:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage
{
    self = [self initWithName:name title:title image:image];
    if (self) {
        _selectedImage = selectedImage;
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

static void const * MITUIViewController_ModuleItemKey = &MITUIViewController_ModuleItemKey;
@implementation UIViewController (MITModuleItem)
- (void)setModuleItem:(MITModuleItem*)moduleItem
{
    objc_setAssociatedObject(self, MITUIViewController_ModuleItemKey, moduleItem, OBJC_ASSOCIATION_RETAIN);
}

- (MITModuleItem*)moduleItem {
    return objc_getAssociatedObject(self, MITUIViewController_ModuleItemKey);
}
@end
