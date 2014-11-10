#import <QuartzCore/QuartzCore.h>
#import "MITTabView.h"
#import "MITTabBar.h"
#import "MITTabHeaderView.h"

NSString * const MITTabViewWillBecomeActiveNotification = @"MITTabViewWillBecomeActive";
NSString * const MITTabViewDidBecomeActiveNotification = @"MITTabViewDidBecomeActive";
NSString * const MITTabViewWillBecomeInactiveNotification = @"MITTabViewWillBecomeInactive";
NSString * const MITTabViewDidBecomeInactiveNotification = @"MITTabViewDidBecomeInactive";

static CGFloat kHeaderDefaultHeight = 5.0;

@interface MITTabView ()
@property (nonatomic,retain) UISegmentedControl *segmentedControl;
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViews;
@property (nonatomic,assign) UIView *activeView;
@property (nonatomic,retain) UIView *activeHeaderView;
@property (nonatomic,retain) UIView *headerView;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)makeViewActive:(UIView*)newView;

- (void)tabViewWillBecomeActive:(UIView*)view;
- (void)tabViewDidBecomeActive:(UIView*)view;

- (void)tabViewWillBecomeInactive:(UIView*)view;
- (void)tabViewDidBecomeInactive:(UIView*)view;
@end

@implementation MITTabView

@dynamic views;

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
    self.tabViews = [NSMutableArray array];
    self.activeView = nil;
    self.autoresizesSubviews = YES;
    
    {
        UISegmentedControl *control = [[[UISegmentedControl alloc] initWithItems:@[@"Loans", @"Fines", @"Holds"]] autorelease];
        control.selectedSegmentIndex = 0;
        control.autoresizingMask = UIViewAutoresizingNone;
        [control addTarget:self
                action:@selector(controlWasTouched:)
      forControlEvents:UIControlEventValueChanged];

        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            UIImage *normalImage = [[UIImage imageNamed:MITImageTabViewInactive] stretchableImageWithLeftCapWidth:10
                                                                                                       topCapHeight:10];
            UIImage *selectedImage = [[UIImage imageNamed:MITImageTabViewActive] stretchableImageWithLeftCapWidth:10
                                                                                                       topCapHeight:10];
            UIImage *highlightImage = [[UIImage imageNamed:MITImageTabViewInactiveHighlighted] stretchableImageWithLeftCapWidth:10
                                                                                                                  topCapHeight:10];
            UIImage *nnDividerImage = [[UIImage imageNamed:MITImageTabViewDivider] stretchableImageWithLeftCapWidth:0 topCapHeight:10];
            
            [control setBackgroundImage:normalImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [control setBackgroundImage:highlightImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [control setBackgroundImage:selectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
            
            [control setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor],
                                              UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.5],
                                              UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -0.5)]}
                                   forState:UIControlStateNormal];
            [control setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]}
                                   forState:UIControlStateHighlighted];
            [control setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor colorWithWhite:0.2 alpha:1.0],
                                              UITextAttributeTextShadowColor: [UIColor whiteColor],
                                              UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 0.5)]}
                                   forState:UIControlStateSelected];
            
            [control setDividerImage:nnDividerImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            
            [control setContentOffset:CGSizeMake(0, 3) forSegmentAtIndex:0];
            [control setContentOffset:CGSizeMake(0, 3) forSegmentAtIndex:1];
            [control setContentOffset:CGSizeMake(15, 3) forSegmentAtIndex:2];
        }
        
        self.segmentedControl = control;
        [self addSubview:control];
    }
    
    {
        MITTabBar *bar = [[[MITTabBar alloc] init] autorelease];
        [bar addTarget:self
                action:@selector(controlWasTouched:)
      forControlEvents:UIControlEventValueChanged];
        
        self.tabControl = bar;
//        [self addSubview:bar];
    }
    
    {
        UIView *header = [[[MITTabHeaderView alloc] initWithFrame:CGRectZero] autorelease];
        header.backgroundColor = [UIColor whiteColor];
        header.layer.masksToBounds = YES;
        header.autoresizingMask = UIViewAutoresizingNone;
        
        self.headerView = header;
        [self addSubview:header];
    }
    
    {
        UIView *contentView = [[[UIView alloc] init] autorelease];
        contentView.autoresizesSubviews = YES;
        contentView.backgroundColor = [UIColor clearColor];
        contentView.layer.masksToBounds = YES;
        
        self.contentView = contentView;
        [self addSubview:contentView];
    }
}

- (void)dealloc
{
    self.tabControl = nil;
    self.tabViews = nil;
    self.contentView = nil;
    self.headerView = nil;
    self.activeHeaderView = nil;
    [super dealloc];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        [self tabViewWillBecomeActive:self.activeView];
    }
}

- (void)didMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        [self tabViewDidBecomeActive:self.activeView];
    }
}

- (void)layoutSubviews
{
    CGRect viewRect = self.bounds;
    CGPoint frameOrigin = viewRect.origin;
    
    CGRect barFrame = CGRectZero;
    CGRect headerFrame = CGRectZero;
    CGRect contentFrame = CGRectZero;
    
    {
        UIEdgeInsets insets = UIEdgeInsetsMake(11., 20., 4., 20.);
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            insets = UIEdgeInsetsMake(11., 5., 0., 5.);
        }
        barFrame = self.segmentedControl.frame;
        barFrame.origin.x = insets.left;
        barFrame.origin.y = frameOrigin.y + insets.top;
        barFrame.size.width = viewRect.size.width - insets.left - insets.right;
        self.segmentedControl.frame = barFrame;
        frameOrigin.y += insets.top + CGRectGetHeight(self.segmentedControl.frame) + insets.bottom;
    }
    
    {
        headerFrame = viewRect;
        headerFrame.origin = frameOrigin;
        headerFrame.size.height = kHeaderDefaultHeight;
        
        if (self.activeHeaderView)
        {
            CGFloat delegateHeight = kHeaderDefaultHeight;
            if ([self.delegate respondsToSelector:@selector(tabView:heightOfHeaderForView:)]) {
                delegateHeight = [self.delegate tabView:self
                                  heightOfHeaderForView:self.activeView];
            }
            
            headerFrame.size.height = delegateHeight;
            frameOrigin.y += CGRectGetHeight(headerFrame);
        }
    }
    
    if (self.tabBarHidden) {
        // At this point, frameOrigin.y is the total vertical offset of the 
        // tabs plus any header. If we translate them up by that amount, they 
        // should slide up under and out of the navbar together without stretching
        barFrame.origin.y -= frameOrigin.y;
        headerFrame.origin.y -= frameOrigin.y;
        frameOrigin = viewRect.origin;
    }

    {
        contentFrame = viewRect;
        contentFrame.origin = frameOrigin;
        contentFrame.size.height -= frameOrigin.y;
    }

    {
        self.activeHeaderView.frame = headerFrame;
        self.segmentedControl.frame = barFrame;
        self.contentView.frame = CGRectStandardize(contentFrame);
        if (self.activeView)
        {
            self.activeView.frame = self.contentView.bounds;
        }
    }
}

- (NSArray*)views
{
    return [NSArray arrayWithArray:self.tabViews];
}

- (void)controlWasTouched:(id)sender
{
    [self selectTabAtIndex:self.segmentedControl.selectedSegmentIndex];
}

- (void)selectTabAtIndex:(NSInteger)index
{
    if (index >= 0) {
        UIView *selectedView = [self.views objectAtIndex:index];
        // short circuit if there is no change
        // if self.activeHeaderView is nil, that means the current tab was never fully selected
        if (selectedView == self.activeView && self.activeHeaderView) {
            return;
        }
        else
        {
            [self makeViewActive:selectedView];
            self.tabControl.selectedSegmentIndex = index;
        }
    } else {
        self.tabControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    }
}

- (void)makeViewActive:(UIView*)newView
{
    UIView *oldView = self.activeView;
    
    [self tabViewWillBecomeInactive:oldView];
    [self tabViewWillBecomeActive:newView];
    
    // Setup the view header, if present
    {
        UIView *activeHeaderView = nil;
        
        if ([self.delegate respondsToSelector:@selector(tabView:headerForView:)])
        {
            activeHeaderView = [self.delegate tabView:self
                                  headerForView:newView];
        }
        else
        {
            activeHeaderView = nil;
        }
        
        if (self.activeHeaderView != activeHeaderView)
        {
            if (self.activeHeaderView)
            {
                [self.activeHeaderView removeFromSuperview];
            }
            
            if (activeHeaderView)
            {
                [self addSubview:activeHeaderView];
            }
            
            self.activeHeaderView = activeHeaderView;
        }
        
    }
    
    // Now setup the active view
    {
        if (oldView) {
            [oldView removeFromSuperview];
        }
        
        if (newView) {
            [self.contentView addSubview:newView];
        }
        
        self.activeView = newView;
    }

    [self setNeedsLayout];
    [self tabViewDidBecomeActive:newView];
    [self tabViewDidBecomeInactive:oldView];
}

- (BOOL)addView:(UIView*)view withItem:(UITabBarItem*)item animate:(BOOL)animate
{
    return [self insertView:view
                   withItem:item
                    atIndex:[self.tabControl.items count]
                    animate:animate];
}

- (BOOL)insertView:(UIView*)view withItem:(UITabBarItem*)item atIndex:(NSInteger)index animate:(BOOL)animate
{
    if ([self.tabViews containsObject:view]) {
        return NO;
    } else if ([item.title length] == 0) {
        return NO;
    }
    
    [self.tabViews addObject:view];
    [self.tabControl insertSegmentWithItem:item
                                    atIndex:index
                                   animated:animate];
    
    if (self.tabControl.selectedSegmentIndex == UISegmentedControlNoSegment) {
        [self selectTabAtIndex:0];
    }
    return YES;
}

- (void)tabViewWillBecomeActive:(UIView*)view
{
    if (view) {
        if ([self.delegate respondsToSelector:@selector(tabView:viewWillBecomeActive:)]) {
            [self.delegate tabView:self
               viewWillBecomeActive:view];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewWillBecomeActiveNotification
                                                            object:self];
    }
}

- (void)tabViewDidBecomeActive:(UIView*)view
{
    if (view) {
        if ([self.delegate respondsToSelector:@selector(tabView:viewDidBecomeActive:)]) {
            [self.delegate tabView:self
               viewDidBecomeActive:view];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewDidBecomeActiveNotification
                                                            object:self];
    }
}

- (void)tabViewWillBecomeInactive:(UIView*)view
{
    if (view) {
        if ([self.delegate respondsToSelector:@selector(tabView:viewWillBecomeInactive:)]) {
            [self.delegate tabView:self
               viewWillBecomeInactive:view];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewWillBecomeInactiveNotification
                                                            object:self];
    }
}

- (void)tabViewDidBecomeInactive:(UIView*)view
{
    if (view)
    {
        if ([self.delegate respondsToSelector:@selector(tabView:viewDidBecomeInactive:)])
        {
            [self.delegate tabView:self
               viewDidBecomeInactive:view];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewDidBecomeInactiveNotification
                                                            object:self];
    }
}

#pragma mark - Dynamic Properties
- (void)setTabBarHidden:(BOOL)tabBarHidden
{
    [self setTabBarHidden:tabBarHidden
                 animated:NO
                 finished:nil];
}

- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated
{
    [self setTabBarHidden:tabBarHidden
                 animated:animated
                 finished:nil];
}

- (void)setTabBarHidden:(BOOL)tabBarHidden animated:(BOOL)animated finished:(void(^)())finishedBlock
{
    if (tabBarHidden != _tabBarHidden)
    {
        _tabBarHidden = tabBarHidden;

        if (tabBarHidden == NO) {
            self.activeHeaderView.hidden = tabBarHidden;
            self.segmentedControl.hidden = tabBarHidden;
        }

        {
            [UIView transitionWithView:self
                              duration:(animated ? 0.3 : 0.0)
                               options:(UIViewAnimationOptionOverrideInheritedCurve |
                                       UIViewAnimationOptionCurveEaseInOut |
                                       UIViewAnimationOptionOverrideInheritedDuration)
                            animations:^{
                                [self layoutSubviews];
                            }
                            completion:^(BOOL finished) {
                                if (finished && finishedBlock)
                                {
                                    if (tabBarHidden == YES) {
                                        self.activeHeaderView.hidden = tabBarHidden;
                                        self.segmentedControl.hidden = tabBarHidden;
                                    }
                                    finishedBlock();
                                }
                            }];
        }
    }
}
@end
