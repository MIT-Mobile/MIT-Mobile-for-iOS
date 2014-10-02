#import "MITModuleViewController.h"
#import "MITUnreadNotifications.h"

@interface MITModuleViewController ()

@end

@implementation MITModuleViewController
@synthesize rootViewController = _rootViewController;
@dynamic isRootViewControllerLoaded;

- (void)loadView
{
    [super loadView];
    
    if (![self isViewLoaded]) {
        UIView *view = [[UIView alloc] init];
        view.autoresizesSubviews = YES;
        view.translatesAutoresizingMaskIntoConstraints = YES;
        self.view = view;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self _loadRootViewControllerIfNeeded];
}

- (BOOL)isRootViewControllerLoaded
{
    return (_rootViewController != nil);
}

- (void)loadRootViewController
{
    if (self.rootViewControllerStoryboardID) {
        self.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.rootViewControllerStoryboardID];
        NSAssert(@"failed to instantiate view controller with StoryboardID %@",self.rootViewControllerStoryboardID);
    } else {
        self.rootViewController = [[UIViewController alloc] init];
    }
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    [self setRootViewController:rootViewController animated:NO];
}

- (void)setRootViewController:(UIViewController *)newRootViewController animated:(BOOL)animated
{
    UIViewController *oldRootViewController = _rootViewController;
    
    if (oldRootViewController != newRootViewController) {
        _rootViewController = newRootViewController;
        
        NSTimeInterval animationDuration = (animated ? 0.33 : 0);
        if (oldRootViewController && newRootViewController) {
            [self transitionFromViewController:oldRootViewController
                              toViewController:newRootViewController
                                      duration:animationDuration
                                       options:0
                                    animations:^{
                                        DDLogVerbose(@"no animations yet...");
                                    } completion:^(BOOL finished) {
                                        DDLogVerbose(@"transition done!");
                                    }];
        } else if (!oldRootViewController && newRootViewController) {
            // Transitioning from an empty view
            // Add the new view controller to the hierarchy.
            //  Be warned: We may be passed something that was pulled out of a nib, so check
            //  before we do anything!
            BOOL didAddChildViewController = NO;
            
            if (self != newRootViewController.parentViewController) {
                didAddChildViewController = YES;
                [self addChildViewController:newRootViewController];
            }
            
            if (![newRootViewController.view isDescendantOfView:self.view]) {
                UIView *rootView = newRootViewController.view;
                rootView.frame = self.view.bounds;
                rootView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
                [self.view addSubview:rootView];
            }
            
            [UIView animateWithDuration:animationDuration animations:^{
                DDLogVerbose(@"No UIView animations yet");
            } completion:^(BOOL finished) {
                if (didAddChildViewController) {
                    [newRootViewController didMoveToParentViewController:self];
                }
            }];
        } else if (oldRootViewController && !newRootViewController) {
            [oldRootViewController willMoveToParentViewController:nil];
            
            [UIView animateWithDuration:animationDuration animations:^{
                DDLogVerbose(@"No UIView animations yet");
            } completion:^(BOOL finished) {
                [oldRootViewController.view removeFromSuperview];
                [newRootViewController didMoveToParentViewController:self];
            }];
        }
    }
}

- (UIViewController*)rootViewController
{
    [self _loadRootViewControllerIfNeeded];
    return _rootViewController;
}

- (BOOL)isCurrentUserInterfaceIdiomSupported
{
    // Support everything by default
    return YES;
}

- (BOOL)canReceivePushNotifications
{
    return NO;
}

- (void)didReceivePushNotification:(NSDictionary*)notification
{
    return;
}

#pragma mark Private
- (void)_loadRootViewControllerIfNeeded
{
    if (![self isRootViewControllerLoaded]) {
        [self loadRootViewController];
    }
}
@end

@implementation MITModuleItem
@synthesize tag = _tag;
@synthesize image = _image;
@synthesize title = _title;

- (instancetype)initWithTag:(NSString*)tag title:(NSString*)title image:(UIImage*)image
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _tag = [tag copy];
        _image = image;
    }
    
    return self;
}

- (instancetype)initWithTag:(NSString*)tag title:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _tag = [tag copy];
        
        _image = image;
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