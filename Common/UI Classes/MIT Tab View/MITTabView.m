#import "MITTabView.h"
#import "MITTabBar.h"

@interface MITTabView ()
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViewControllers;
@property (nonatomic,assign) UIViewController *activeController;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)selectTabAtIndex:(NSInteger)index;
@end

@implementation MITTabView
@synthesize activeController = _activeController,
			contentView = _contentView,
			tabControl = _tabControl,
			tabViewControllers = _tabViewControllers;
@dynamic viewControllers;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self privateInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self privateInit];
    }
    
    return self;
}

- (void)privateInit
{
    self.tabViewControllers = [NSMutableArray array];
    self.tabControl = [[[MITTabBar alloc] init] autorelease];
    self.contentView = [[[UIView alloc] init] autorelease];
    self.activeController = nil;
    [self layoutSubviews];
    [self selectTabAtIndex:UISegmentedControlNoSegment];
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)dealloc
{
    self.tabControl = nil;
    self.tabViewControllers = nil;
    self.contentView = nil;
    [super dealloc];
}

- (void)layoutSubviews
{ 
    CGRect viewFrame = self.frame;
    viewFrame.origin = CGPointZero;
    
    {
        self.tabControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        if ([[self.tabControl actionsForTarget:self forControlEvent:UIControlEventValueChanged] count] == 0) {
            [self.tabControl addTarget:self
                                action:@selector(controlWasTouched:)
                      forControlEvents:UIControlEventAllEvents];
            NSLog(@"%@",[self.tabControl allTargets]);
        }
        
        CGRect frame = self.tabControl.frame;
        frame.origin = CGPointZero;
        frame.size.width = CGRectGetWidth(viewFrame);
        frame.size.height = [self.tabControl sizeThatFits:viewFrame.size].height;
        self.tabControl.frame = frame;
        
        if ([self.tabControl superview] == nil) {
            [self addSubview:self.tabControl];
        }
    }
    
    {
        CGFloat height = self.tabControl.frame.size.height;
        CGRect contentFrame = viewFrame;
        contentFrame.origin = CGPointMake(0, height);
        contentFrame.size.height -= height;

        self.contentView.frame = contentFrame;
        self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        self.contentView.autoresizesSubviews = YES;
        
        if ([self.contentView superview] == nil) {
            [self addSubview:self.contentView];
        }
    }
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
