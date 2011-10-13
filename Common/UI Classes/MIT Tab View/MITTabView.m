#import "MITTabView.h"
#import "MITTabBar.h"
#import "MITTabViewItem.h"

NSString* const MITTabViewWillBecomeActiveNotification = @"MITTabViewWillBecomeActive";
NSString* const MITTabViewDidBecomeActiveNotification = @"MITTabViewDidBecomeActive";
NSString* const MITTabViewWillBecomeInactiveNotification = @"MITTabViewWillBecomeInactive";
NSString* const MITTabViewDidBecomeInactiveNotification = @"MITTabViewDidBecomeInactive";

@interface MITTabView ()
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViews;
@property (nonatomic,assign) UIView *activeView;
@property (nonatomic,retain) UIView *headerView;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)selectTabAtIndex:(NSInteger)index;

- (void)tabViewWillBecomeActive:(UIView*)view;
- (void)tabViewDidBecomeActive:(UIView*)view;

- (void)tabViewWillBecomeInactive:(UIView*)view;
- (void)tabViewDidBecomeInactive:(UIView*)view;
@end

@implementation MITTabView
@synthesize activeView = _activeView,
			contentView = _contentView,
            delegate = _delegate,
			tabControl = _tabControl,
			tabViews = _tabViews,
            headerView = _headerView;
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
    self.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    [self layoutSubviews];
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
    
    {
        CGRect barFrame = CGRectZero;
        barFrame.size = CGSizeMake(CGRectGetWidth(viewRect), 28);
        
        if (self.tabControl == nil) {
            MITTabBar *bar = [[[MITTabBar alloc] initWithFrame:barFrame] autorelease];
            [bar addTarget:self
                    action:@selector(controlWasTouched:)
          forControlEvents:UIControlEventValueChanged];
        
            self.tabControl = bar;
            [self addSubview:bar];
        } else {
            self.tabControl.frame = barFrame;
        }
    }
    
    {
        CGRect headerFrame = viewRect;
        headerFrame.origin.y += self.tabControl.frame.size.height;
        headerFrame.size.height = 5.0;
        
        UIView *header = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
        header.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight);
        header.autoresizesSubviews = YES;
    }
    
    {
        CGRect subviewFrame = viewRect;
        subviewFrame.origin.y = self.tabControl.frame.size.height;
        subviewFrame.size.height -= self.tabControl.frame.size.height;
        
        if (self.contentView == nil) {
            UIView *view = [[[UIView alloc] initWithFrame:subviewFrame] autorelease];
            self.contentView = view;
            [self addSubview:view];
        } else {
            self.contentView.frame = subviewFrame;
        }
        
        self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        self.contentView.autoresizesSubviews = YES;
        self.contentView.backgroundColor = [UIColor clearColor];
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
        UIView *activeView = [self.views objectAtIndex:index];
        if (activeView == self.activeView) {
            return;
        }
        else if (self.activeView)
        { 
            [self tabViewWillBecomeInactive:self.activeView];
            [self.activeView removeFromSuperview];
            [self tabViewDidBecomeInactive:self.activeView];
            self.activeView = nil;
        }
        
        activeView.frame = self.contentView.bounds;
        
        [self tabViewWillBecomeActive:activeView];
        [self.contentView addSubview:activeView];
        [self tabViewDidBecomeActive:activeView];
        
        self.tabControl.selectedSegmentIndex = index;
        self.activeView = activeView;
    } else {
        self.tabControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    }
}

- (BOOL)addView:(UIView*)view withItem:(MITTabViewItem*)item animate:(BOOL)animate
{
    return [self insertView:view
                   withItem:item
                    atIndex:[self.tabControl.items count]
                    animate:animate];
}

- (BOOL)insertView:(UIView*)controller withItem:(MITTabViewItem*)item atIndex:(NSInteger)index animate:(BOOL)animate
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
