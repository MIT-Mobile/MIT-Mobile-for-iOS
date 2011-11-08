#import <QuartzCore/QuartzCore.h>
#import "MITTabView.h"
#import "MITTabBar.h"
#import "MITGradientView.h"

NSString* const MITTabViewWillBecomeActiveNotification = @"MITTabViewWillBecomeActive";
NSString* const MITTabViewDidBecomeActiveNotification = @"MITTabViewDidBecomeActive";
NSString* const MITTabViewWillBecomeInactiveNotification = @"MITTabViewWillBecomeInactive";
NSString* const MITTabViewDidBecomeInactiveNotification = @"MITTabViewDidBecomeInactive";

static NSUInteger kHeaderDefaultHeight = 5.0;

@interface MITTabView ()
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViews;
@property (nonatomic,assign) UIView *activeView;
@property (nonatomic,retain) UIView *activeHeaderView;
@property (nonatomic,retain) UIView *headerView;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)selectTabAtIndex:(NSInteger)index;
- (void)makeViewActive:(UIView*)newView;

- (void)tabViewWillBecomeActive:(UIView*)view;
- (void)tabViewDidBecomeActive:(UIView*)view;

- (void)tabViewWillBecomeInactive:(UIView*)view;
- (void)tabViewDidBecomeInactive:(UIView*)view;
@end

@implementation MITTabView
@synthesize delegate = _delegate,
            contentView = _contentView;

@synthesize activeView = _activeView,
			tabControl = _tabControl,
			tabViews = _tabViews,
            headerView = _headerView,
            activeHeaderView = _activeHeaderView;

@dynamic views;

- (id)init
{
    self = [super init];
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
    self.tabViews = [NSMutableArray array];
    self.activeView = nil;
    self.autoresizesSubviews = YES;
    
    {
        MITTabBar *bar = [[[MITTabBar alloc] init] autorelease];
        [bar addTarget:self
                action:@selector(controlWasTouched:)
      forControlEvents:UIControlEventValueChanged];
        
        self.tabControl = bar;
        [self addSubview:bar];
    }
    
    {
        UIView *header = [[[MITGradientView alloc] initWithFrame:CGRectZero] autorelease];
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
    
    {
        CGRect barFrame = CGRectZero;
        barFrame.origin = frameOrigin;
        barFrame.size = CGSizeMake(CGRectGetWidth(viewRect), 28);
        self.tabControl.frame = barFrame;
        
        frameOrigin.y += CGRectGetHeight(barFrame);
    }
    
    {
        CGRect headerFrame = viewRect;
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
            self.activeHeaderView.frame = CGRectStandardize(headerFrame);
            frameOrigin.y += CGRectGetHeight(headerFrame);
        }
        
    }
    
    {
        CGRect subviewFrame = viewRect;
        subviewFrame.origin = frameOrigin;
        subviewFrame.size.height -= frameOrigin.y;

        self.contentView.frame = CGRectStandardize(subviewFrame);
        
        if (self.activeView) {
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
    [self selectTabAtIndex:self.tabControl.selectedSegmentIndex];
}

- (void)selectTabAtIndex:(NSInteger)index
{
    if (index >= 0) {
        UIView *selectedView = [self.views objectAtIndex:index];
        if (selectedView == self.activeView) {
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

- (BOOL)insertView:(UIView*)controller withItem:(UITabBarItem*)item atIndex:(NSInteger)index animate:(BOOL)animate
{
    if ([self.tabViews containsObject:controller]) {
        return NO;
    } else if ([item.title length] == 0) {
        return NO;
    }
    
    [self.tabViews addObject:controller];
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
    if (view) {
        if ([self.delegate respondsToSelector:@selector(tabView:viewDidBecomeInactive:)]) {
            [self.delegate tabView:self
               viewDidBecomeInactive:view];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewDidBecomeInactiveNotification
                                                            object:self];
    }
}
@end
