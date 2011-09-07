#import "MITTabViewController.h"
#import "MITTabBar.h"

@interface MITTabViewController ()
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViewControllers;
@property (nonatomic,assign) UIViewController *activeController;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)selectTabAtIndex:(NSInteger)index;
@end

@implementation MITTabViewController
@synthesize activeController = _activeController,
			contentView = _contentView,
			tabControl = _tabControl,
			tabViewControllers = _tabViewControllers;
@dynamic viewControllers;

- (id)init
{
    self = [super init];
    if (self) {
        [self privateInit];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        [self privateInit];
    }
    
    return self;
}

- (void)privateInit
{
    self.tabViewControllers = [NSMutableArray array];
    self.activeController = nil;
}

- (void)dealloc
{
    self.tabControl = nil;
    self.tabViewControllers = nil;
    self.contentView = nil;
    [super dealloc];
}

- (void)loadView
{
    CGRect viewRect = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:viewRect] autorelease];
    
    mainView.autoresizesSubviews = YES;
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    
    {
        CGRect barFrame = CGRectZero;
        barFrame.size = CGSizeMake(CGRectGetWidth(viewRect), 28);
        
        MITTabBar *bar = [[[MITTabBar alloc] initWithFrame:barFrame] autorelease];
        [bar addTarget:self
                action:@selector(controlWasTouched:)
      forControlEvents:UIControlEventValueChanged];
        
        self.tabControl = bar;
        [mainView addSubview:bar];
    }
    
    {
        CGRect subviewFrame = viewRect;
        subviewFrame.origin.y = self.tabControl.frame.size.height;
        subviewFrame.size.height -= self.tabControl.frame.size.height;
        
        UIView *view = [[[UIView alloc] initWithFrame:subviewFrame] autorelease];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
        view.autoresizesSubviews = YES;
        view.backgroundColor = [UIColor clearColor];
        self.contentView = view;
        [mainView addSubview:view];
    }
    
    [self setView:mainView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self selectTabAtIndex:0];
}

- (NSArray*)viewControllers
{
    return [NSArray arrayWithArray:self.tabViewControllers];
}

- (void)controlWasTouched:(id)sender
{
    [self selectTabAtIndex:self.tabControl.selectedSegmentIndex];
}

- (void)selectTabAtIndex:(NSInteger)index
{
    if (index >= [self.viewControllers count]) {
        return;
    } else if (self.activeController == [self.viewControllers objectAtIndex:index]) {
        return;
    } else {
        if (self.activeController) {
            [self.activeController viewWillDisappear:NO];
            [[self.activeController view] removeFromSuperview];
            [self.activeController viewDidDisappear:NO];
            self.activeController = nil;
        }
        
        if (index >= 0) {
            self.activeController = [self.viewControllers objectAtIndex:index];
            self.activeController.view.frame = self.contentView.bounds;
            
            [self.activeController viewWillAppear:NO];
            [self.contentView addSubview:self.activeController.view];
            [self.activeController viewDidAppear:NO];
            
            self.tabControl.selectedSegmentIndex = index;
        } else {
            self.tabControl.selectedSegmentIndex = UISegmentedControlNoSegment;
        }
    }
}

- (BOOL)addViewController:(UIViewController*)controller animate:(BOOL)animate
{
    NSUInteger index = (([self.tabControl.items count] == 0) ? 0 : ([self.tabControl.items count] - 1));
    return [self insertViewController:controller
                              atIndex:index
                              animate:animate];
}

- (BOOL)insertViewController:(UIViewController*)controller atIndex:(NSUInteger)index animate:(BOOL)animate
{
    if ([self.tabViewControllers containsObject:controller]) {
        return NO;
    } else if ([controller.title length] == 0) {
        return NO;
    }
    
    [self.tabViewControllers addObject:controller];
    [self.tabControl insertSegmentWithTitle:controller.title
                                    atIndex:index
                                   animated:animate];
    
    if (self.tabControl.selectedSegmentIndex == UISegmentedControlNoSegment) {
        [self selectTabAtIndex:0];
    }
    return YES;
}
@end
