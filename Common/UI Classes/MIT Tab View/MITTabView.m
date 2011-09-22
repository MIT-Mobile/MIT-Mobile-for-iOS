#import "MITTabView.h"
#import "MITTabBar.h"

NSString* const MITTabViewWillBecomeActiveNotification = @"MITTabViewWillBecomeActive";
NSString* const MITTabViewDidBecomeActiveNotification = @"MITTabViewDidBecomeActive";
NSString* const MITTabViewWillBecomeInactiveNotification = @"MITTabViewWillBecomeInactive";
NSString* const MITTabViewDidBecomeInactiveNotification = @"MITTabViewDidBecomeInactive";

@interface MITTabView ()
@property (nonatomic,retain) MITTabBar *tabControl;
@property (nonatomic,retain) UIView *contentView;
@property (nonatomic,retain) NSMutableArray *tabViews;
@property (nonatomic,assign) UIView *activeView;

- (void)privateInit;
- (void)controlWasTouched:(id)sender;
- (void)selectTabAtIndex:(NSInteger)index;
@end

@implementation MITTabView
@synthesize activeView = activeView,
			contentView = _contentView,
			tabControl = _tabControl,
			tabViews = _tabViews;
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
    if (newSuperview && self.activeView) {
        [self tabViewWillBecomeActive:self.activeView];
    }
}

- (void)didMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview && self.activeView) {
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
    if (index >= [self.views count]) {
        return;
    } else if (self.activeView == [self.views objectAtIndex:index]) {
        return;
    } else {
        if (self.activeView) { 
            [self tabViewWillBecomeInactive:self.activeView];
            [self.activeView removeFromSuperview];
            [self tabViewDidBecomeInactive:self.activeView];
            self.activeView = nil;
        }
        
        if (index >= 0) {
            self.activeView = [self.views objectAtIndex:index];
            self.activeView.frame = self.contentView.bounds;
            
            [self tabViewWillBecomeActive:self.activeView];
            [self.contentView addSubview:self.activeView];
            [self tabViewDidBecomeActive:self.activeView];
            
            self.tabControl.selectedSegmentIndex = index;
        } else {
            self.tabControl.selectedSegmentIndex = UISegmentedControlNoSegment;
        }
    }
}

- (BOOL)addView:(UIView*)view withItem:(UITabBarItem*)item animate:(BOOL)animate
{
    return [self insertView:view
                   withItem:item
                    atIndex:[self.tabControl.items count]
                    animate:animate];
}

- (BOOL)insertView:(UIView*)controller withItem:(UITabBarItem*)item atIndex:(NSUInteger)index animate:(BOOL)animate
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
    
    NSLog(@"%d",self.tabControl.selectedSegmentIndex);
    if (self.tabControl.selectedSegmentIndex == UISegmentedControlNoSegment) {
        [self selectTabAtIndex:0];
    }
    return YES;
}

- (void)tabViewWillBecomeActive:(UIView*)view
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewWillBecomeActiveNotification
                                                        object:self];
}

- (void)tabViewDidBecomeActive:(UIView*)view
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewDidBecomeActiveNotification
                                                        object:self];
    
}

- (void)tabViewWillBecomeInactive:(UIView*)view
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewWillBecomeInactiveNotification
                                                        object:self];
}

- (void)tabViewDidBecomeInactive:(UIView*)view
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MITTabViewDidBecomeInactiveNotification
                                                        object:self];
}
@end
