#import "MITRootViewController.h"
#import "ECSlidingViewController.h"
#import "MITModule.h"

@interface MITRootViewController ()
@property (nonatomic,strong) NSArray *availableModules;
@property (nonatomic,weak) UIViewController *drawerViewController;
@property (nonatomic,weak) UIViewController *springboardViewController;
@end

@implementation MITRootViewController {
    BOOL _needsInitialTransition;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    _needsInitialTransition = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self transitionToInterfaceStyle:self.interfaceStyle animated:NO];
}

#pragma mark


#pragma mark Changing the interface style
- (void)transitionToInterfaceStyle:(MITInterfaceStyle)style animated:(BOOL)animated
{
    if (_needsInitialTransition || (self.interfaceStyle != style)) {
        MITInterfaceStyle oldStyle = self.interfaceStyle;
        [self willTransitionToInterfaceStyle:style animated:animated];
        
        [self didTransitionFromInterfaceStyle:oldStyle animated:animated];
        _needsInitialTransition = NO;
    }
}

- (void)willTransitionToInterfaceStyle:(MITInterfaceStyle)newStyle animated:(BOOL)animated
{
    
}

- (void)didTransitionFromInterfaceStyle:(MITInterfaceStyle)oldStyle animated:(BOOL)animated
{
    
}

@end
