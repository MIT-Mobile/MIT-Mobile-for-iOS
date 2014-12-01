#import <objc/runtime.h>

#import "MITModule.h"
#import "MITModuleItem.h"

@implementation MITModule
- (instancetype)initWithName:(NSString*)name title:(NSString*)title
{
    NSParameterAssert(name);
    NSParameterAssert(title);
    
    self = [super init];
    if (self) {
        _name = [name copy];
        _title = [title copy];
    }
    
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    return (currentUserInterfaceIdiom == UIUserInterfaceIdiomPhone);
}

- (BOOL)isViewControllerLoaded
{
    return (_viewController != nil);
}

- (UIViewController*)viewController
{
    if (![self isViewControllerLoaded]) {
        [self loadViewController];
        NSAssert(_viewController, @"failed to load view controller");
        [self viewControllerDidLoad];
    }
    
    return _viewController;
}

- (void)loadViewController
{
    UIView *view = [[UIView alloc] init];
    view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    view.backgroundColor = [UIColor whiteColor];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = view;
    
    self.viewController = viewController;
}

- (void)viewControllerDidLoad
{
    self.viewController.moduleItem = [[MITModuleItem alloc] initWithName:self.name title:self.title image:self.image];
}


- (void)didReceiveNotification:(NSDictionary*)userInfo
{
    // Do Nothing
}

- (void)didReceiveRequestWithURL:(NSURL*)url
{
    NSAssert([url.scheme isEqualToString:MITInternalURLScheme],@"malformed internal URL: expected scheme %@ but got %@.",MITInternalURLScheme,url.scheme);
    NSAssert([url.host isEqualToString:self.name], @"malformed internal URL: expected host %@ but got %@",self.name,url.host);
}

- (NSString*)longTitle
{
    if (!_longTitle) {
        return self.title;
    } else {
        return _longTitle;
    }
}

- (UIImage*)image
{
    if (_image) {
        return _image;
    } else if (self.imageName) {
        return [UIImage imageNamed:self.imageName];
    } else {
        return nil;
    }
}

@end
