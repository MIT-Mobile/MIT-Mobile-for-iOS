#import "MITTabBar.h"
#import "MITSegmentControl.h"

@interface MITTabBar ()
@property (nonatomic,retain) NSArray *tabViews;
@property (nonatomic,retain) MITSegmentControl *selectedControl;

- (void)internalInit;
- (void)updateTabs;
- (void)controlWasTouched:(id)sender withEvent:(UIEvent*)event;
@end

@implementation MITTabBar
@synthesize items = _items,
            tabImage = _tabImage,
			tintColor = _tintColor,
			selectedSegmentIndex = _selectedSegmentIndex,
            selectedTabImage = _selectedTabImage,
			selectedTintColor = _selectedTintColor;
			
@synthesize tabViews = _tabViews,
            selectedControl = _selectedControl;

- (id)init
{
    self = [super init];
    if (self)
    {
        [self internalInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (void)internalInit
{
    self.tabViews = nil;
    self.items = nil;
    self.selectedSegmentIndex = UISegmentedControlNoSegment;
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    if ([self.items count] > 0)
    {
        if (self.tabViews == nil)
        {
            NSMutableArray *array = [NSMutableArray array];
            NSInteger tag = 0;
            
            for (UITabBarItem *item in self.items)
            {
                MITSegmentControl *control = [[[MITSegmentControl alloc] initWithTabBarItem:item] autorelease];
                control.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                control.tag = tag;
                
                UIImage *normalImage = [[UIImage imageNamed:MITImageTabViewInactive] stretchableImageWithLeftCapWidth:10
                                                                                                           topCapHeight:10];
                UIImage *selectedImage = [[UIImage imageNamed:MITImageTabViewActive] stretchableImageWithLeftCapWidth:10
                                                                                                           topCapHeight:10];
                UIImage *highlightImage = [[UIImage imageNamed:MITImageTabViewInactiveHighlighted] stretchableImageWithLeftCapWidth:10
                                                                                                                      topCapHeight:10];
                [control setTabImage:normalImage
                            forState:UIControlStateNormal];
                [control setTabImage:highlightImage
                            forState:UIControlStateHighlighted];
                [control setTabImage:selectedImage
                            forState:UIControlStateSelected];
                [control setTabImage:selectedImage
                            forState:(UIControlStateSelected | UIControlStateHighlighted)];
                
                [control setTitleColor:[UIColor whiteColor]
                              forState:UIControlStateNormal];
                
                
                [control addTarget:self
                            action:@selector(controlWasTouched:withEvent:)
                  forControlEvents:UIControlEventTouchUpInside];
                
                [array addObject:control];
                [self addSubview:control];
                ++tag;
            }
            
            self.tabViews = ([array count] > 0) ? array : nil;
        }
    
        // divide the width equally between segments
        // but lop off 3px from each side
        // and add 1px between each segment
        CGFloat width = (self.bounds.size.width - (6.0 + [self.items count] - 1)) / [self.items count];
        
        CGRect rect = CGRectZero;
        rect.origin = CGPointMake(self.bounds.origin.x + 3.0, self.bounds.origin.y + 1.0);
        rect.size = CGSizeMake(width, self.bounds.size.height);
        
        for (MITSegmentControl *control in self.tabViews)
        {
            control.frame = rect;
            rect.origin.x += width + 1.0;
        }
        
        [self updateTabs];
    }
}
     
#pragma mark - Custom mutators
- (void)setItems:(NSArray *)items
{
    [self->_items release];
    self->_items = [items copy];
    
    for (UIView *view in self.tabViews) {
        [view removeFromSuperview];
    }
    
    self.tabViews = nil;
    [self layoutSubviews];
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [self->_tintColor release];
    self->_tintColor = [tintColor retain];
    
    for (MITSegmentControl *segment in self.tabViews)
    {
        [segment setTitleColor:tintColor
                      forState:UIControlStateNormal];
    }
}

- (void)setSelectedTintColor:(UIColor *)selectedTintColor
{
    [self->_selectedTintColor release];
    self->_selectedTintColor = [selectedTintColor retain];
    
    for (MITSegmentControl *segment in self.tabViews)
    {
        [segment setTitleColor:selectedTintColor
                      forState:UIControlStateSelected];
    }
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    self->_selectedSegmentIndex = selectedSegmentIndex;
    [self updateTabs];
}

- (void)updateTabs
{
    for (int i = 0; i < [self.tabViews count]; ++i) {
        MITSegmentControl *control = [self.tabViews objectAtIndex:i];
        
        if (i == self.selectedSegmentIndex) {
            control.selected = YES;
        } else {
            control.selected = NO;
        }
        
        [control setNeedsDisplay];
    }
    
}

#pragma mark - Touch Event Handling

- (void)controlWasTouched:(id)sender withEvent:(UIEvent*)event
{
    NSInteger index = [(UIControl*)sender tag];
    
    if (index == self.selectedSegmentIndex) {
        return;
    }
    else if (index < [self.tabViews count])
    {
        self.selectedSegmentIndex = index;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)insertSegmentWithItem:(UITabBarItem*)item atIndex:(NSInteger)index animated:(BOOL)animated
{
    id selectedItem = nil;
    NSInteger selectedIndex = self.selectedSegmentIndex;
    if (selectedIndex >= 0) { 
        selectedItem = [self.items objectAtIndex:selectedIndex];
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.items];
    [array insertObject:item
                atIndex:index];
    
    if (selectedItem) {
        // Adjust the index of the selected item to account for the fact
        // that it may have shifted due to the insertion.
        self.selectedSegmentIndex = [array indexOfObject:selectedItem];
    }
    
    self.items = array;
}


- (void)removeSegmentWithItem:(UITabBarItem*)item animated:(BOOL)animated
{
    
}

- (void)removeSegmentAtIndex:(NSInteger)index animated:(BOOL)animated
{
    
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize viewSize = CGSizeZero;
    
    if ([self.tabViews count]) 
    {
        CGSize tabSize = [[self.tabViews objectAtIndex:0] sizeThatFits:size];
        
        viewSize.height = tabSize.height;
    }
    else
    {
        viewSize.height = MAX(viewSize.height,28.0);
    }
    
    return viewSize;
}

@end
