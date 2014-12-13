#import "TabViewControl.h"

#define kTabFontSize 15
#define kTabCurveRadius 8 
#define kTabTextPadding 22 // px between tab and start of text 
#define kTabSapcing 4      // px between tabs

#define kUnselectedFillColorR 153.0
#define kUnselectedFillColorG 172.0
#define kUnselectedFillColorB 191.0

#define kSelectedFillColorR 255.0 
#define kSelectedFillColorG 255.0
#define kSelectedFillColorB 255.0

#define kTabFontColorR 50.0
#define kTabFontColorG 58.0
#define kTabFontColorB 77.0

#define MakeUIColor(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]

@interface TabViewControl(Private) 

- (int)tabIndexAtLocation:(CGPoint)point;

@end


@implementation TabViewControl
@dynamic selectedTab;
@synthesize tabs = _tabs;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.opaque = NO;
		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
		_pressedTab = -1;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.opaque = NO;

		[self addTarget:self action:@selector(touchUpInside:forEvent:) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(touchDown:forEvent:) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(touchUpOutside:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
		_pressedTab = -1;
	}
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	if (nil == _tabFont) {
		_tabFont = [[UIFont boldSystemFontOfSize:kTabFontSize] retain];
	}
	
	CGContextRef dc =  UIGraphicsGetCurrentContext();
	

	
	int tabOffset = 10;
	CGFloat nonselectedComponents[8] = {  0.65, 0.65, 0.65, 1.0, 0.45, 0.45, 0.45, 1.0 };
	CGFloat selectedComponents[8] = {  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
	CGFloat pressedComponents[8] = {  0.4, 0.4, 0.4, 1.0, 0.54, 0.54, 0.54, 1.0 };
	
	for (int tabIdx = 0; tabIdx < self.tabs.count; tabIdx++) 
	{
		
		NSString* tabText = [self.tabs objectAtIndex:tabIdx];

		CGGradientRef myGradient;
		CGColorSpaceRef myColorspace;
		
		size_t num_locations = 2;
		CGFloat locations[2] = {0.0, 1.0};
		
		CGFloat* components = nil;
		if (self.selectedTab == tabIdx) {
			components = selectedComponents;
		}
		else if(_pressedTab == tabIdx)
		{
			components = pressedComponents;
		}
		else {
			components = nonselectedComponents;
		}

		
		myColorspace = CGColorSpaceCreateDeviceRGB();// CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
		
		CGPoint gradientStartPoint = CGPointMake(0, 0);
		CGPoint gradientEndPoint = CGPointMake(0, self.frame.size.height);
		
		
		CGContextSaveGState(dc);
		
		CGContextBeginPath(dc);
		
		
		//
		// draw the first curve
		//
		CGRect currentRect = CGRectMake(tabOffset, 0, kTabCurveRadius * 2, kTabCurveRadius * 2);
		CGContextAddEllipseInRect(dc, currentRect);
		
		// measure the string
		CGSize textSize = [tabText sizeWithFont:_tabFont];
		
		//
		// fill the box
		//
		currentRect = CGRectMake(tabOffset + kTabCurveRadius, 0, textSize.width + kTabTextPadding * 2 - kTabCurveRadius * 2, self.frame.size.height);
		CGContextAddRect(dc, currentRect);
		currentRect = CGRectMake(tabOffset, kTabCurveRadius, kTabCurveRadius, self.frame.size.height - kTabCurveRadius);
		CGContextAddRect(dc, currentRect);
		currentRect = CGRectMake(tabOffset + textSize.width + kTabTextPadding * 2 - kTabCurveRadius, kTabCurveRadius, kTabCurveRadius, self.frame.size.height - kTabCurveRadius);
		CGContextAddRect(dc, currentRect);
		

		//
		// draw the second curve
		//
		currentRect = CGRectMake(tabOffset + textSize.width + kTabTextPadding * 2 - kTabCurveRadius * 2,
								 0, kTabCurveRadius * 2, kTabCurveRadius * 2);
		
		CGContextAddEllipseInRect(dc, currentRect);
				
		// Fill the path
		//CGContextFillPath(dc);
		
		CGContextClip(dc);
		CGContextDrawLinearGradient (dc, myGradient, gradientStartPoint, gradientEndPoint, 0);
		
		CGContextRestoreGState(dc);
		
		CGColorSpaceRelease(myColorspace);
		CGGradientRelease(myGradient);
		
		// draw the text
		UIColor* textColor  = (self.selectedTab == tabIdx) ? [UIColor blackColor] : [UIColor whiteColor];
		
		CGContextSetFillColorWithColor(dc, textColor.CGColor);
		CGRect textRect = CGRectMake(tabOffset + kTabTextPadding, (self.frame.size.height - textSize.height) / 2, textSize.width, textSize.height);
		[tabText drawInRect:textRect withFont:_tabFont];
				
		
		// set the offset for the next tab
		tabOffset = currentRect.origin.x + currentRect.size.width + kTabSapcing;

		
	}
	
	
	
	
}

- (int)tabIndexAtLocation:(CGPoint)point
{
	
	int tabIndex = -1;
	
	int tabOffset = 20;
	
	for (int tabIdx = 0; tabIdx < self.tabs.count; tabIdx++) {
		NSString* tabText = [self.tabs objectAtIndex:tabIdx];
		
		// construct the rect for this tab
		// measure the string
		CGSize textSize = [tabText sizeWithFont:_tabFont];
		CGRect currentRect = CGRectMake(tabOffset, 0, textSize.width + kTabTextPadding * 2, self.frame.size.height);
		
		if (CGRectContainsPoint(currentRect, point)) {
			tabIndex = tabIdx;
			break;
		}
		
		tabOffset = currentRect.origin.x + currentRect.size.width + kTabSapcing;
	}
	
	return tabIndex;
	
}

-(void) touchUpOutside:(id)sender forEvent:(UIEvent *)event
{
	_pressedTab = -1;
	[self setNeedsDisplay];
}

-(void) touchDown:(id)sender forEvent:(UIEvent *)event
{
	NSSet* touches = [event touchesForView:self];
	
	UITouch* touch = [touches anyObject];
	
	// hit test that touch
	CGPoint touchLocation = [touch locationInView:self];
	
	_pressedTab = [self tabIndexAtLocation:touchLocation];
	[self setNeedsDisplay];
}


-(void) touchUpInside:(id)sender forEvent:(UIEvent *)event
{
	if(sender != self)
		return;
	
	_pressedTab = -1;
	
	NSSet* touches = [event touchesForView:self];
	
	UITouch* touch = [touches anyObject];
	
	// hit test that touch
	CGPoint touchLocation = [touch locationInView:self];
	
	int tabIndex = [self tabIndexAtLocation:touchLocation];
	
	if (tabIndex >= 0) {
		self.selectedTab = tabIndex;
	}
	
	[self setNeedsDisplay];
		
}

- (int)addTab:(NSString*) tabName
{
	if(nil == self.tabs)
	{
		self.tabs = [NSArray arrayWithObject:tabName];
	}
	else {
		NSMutableArray* tabs = [NSMutableArray arrayWithArray:self.tabs];
		[tabs addObject:tabName];
		self.tabs = [NSArray arrayWithArray:tabs];
	}
	
	return (int)self.tabs.count - 1;

}

- (int)selectedTab {
    return _selectedTab;
}

- (void)setSelectedTab:(int)selectedTab
{
    if (_selectedTab != selectedTab) {
        _selectedTab = selectedTab;

        if ([self.delegate respondsToSelector:@selector(tabControl:changedToIndex:tabText:)]) {
            [self.delegate tabControl:self
                       changedToIndex:_selectedTab
                              tabText:self.tabs[_selectedTab]];
        }

        [self setNeedsDisplay];
    }
}

- (void)dealloc {
	
	self.tabs = nil;
	[_tabFont release];
	
    [super dealloc];
}


@end
