#import "NavScrollerView.h"
#import "UIKit+MITAdditions.h"

@implementation NavScrollerView

@synthesize buttons = _buttons, leftScrollButton = _leftScrollButton,
rightScrollButton = _rightScrollButton, contentView = _contentView,
scrollView = _scrollView, navScrollerDelegate, currentXOffset = _currentXOffset;

// make sure no subview created by this class clashes with button tags set by users
#define SELF_TAG 1000
#define SCROLL_VIEW_TAG 1001
#define CONTENT_VIEW_TAG 1002
#define LEFT_SCROLL_BUTTON_TAG 1003
#define RIGHT_SCROLL_BUTTON_TAG 1004
// button subviews
#define BUTTON_TITLE_LABEL_TAG 1005
#define BUTTON_IMAGE_TAG 1006

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.buttons = [NSMutableArray array];
        self.scrollView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
        self.scrollView.delegate = self;
        self.scrollView.scrollsToTop = NO; // otherwise this competes with the story list for status bar taps
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.tag = SCROLL_VIEW_TAG;
        self.contentView = [[[UIView alloc] initWithFrame:frame] autorelease];
        self.contentView.tag = CONTENT_VIEW_TAG;
        self.currentXOffset = 0.0;
        _pressedButton = nil;
        
        self.opaque = NO;
        self.tag = SELF_TAG;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // create background image for scrolling view
    UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
    //UIImageView *imageView = [[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
    //imageView.tag = 1005;
    //[self addSubview:imageView];
    //[imageView release];
	[self setBackgroundColor:[UIColor colorWithPatternImage:backgroundImage]];

    [self.scrollView addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.frame.size;
    [self addSubview:self.scrollView];
    
    // allow a few pixel overflow before we start adding scroll buttons
    // TODO: stop cheating
    if (self.contentView.frame.size.width > self.frame.size.width + 10) {
        if (!self.leftScrollButton) {
            UIImage *leftScrollImage = [UIImage imageNamed:MITImageNameScrollTabLeftEndCap];
            self.leftScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.leftScrollButton setImage:leftScrollImage forState:UIControlStateNormal];
            CGRect imageFrame = CGRectMake(0,0,leftScrollImage.size.width,leftScrollImage.size.height);
            self.leftScrollButton.frame = imageFrame;
            self.leftScrollButton.hidden = YES;
            self.leftScrollButton.tag = LEFT_SCROLL_BUTTON_TAG;
            [self.leftScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:self.leftScrollButton];
        
        if (!self.rightScrollButton) {
            UIImage *rightScrollImage = [UIImage imageNamed:MITImageNameScrollTabRightEndCap];
            self.rightScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.rightScrollButton setImage:rightScrollImage forState:UIControlStateNormal];
            CGRect imageFrame = CGRectMake(self.frame.size.width - rightScrollImage.size.width,0,rightScrollImage.size.width,rightScrollImage.size.height);
            self.rightScrollButton.frame = imageFrame;
            self.rightScrollButton.hidden = NO;
            self.rightScrollButton.tag = RIGHT_SCROLL_BUTTON_TAG;
            [self.rightScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:self.rightScrollButton];
    }
}

- (void)removeAllButtons {
    for (UIButton *aButton in _buttons) {
        [aButton removeFromSuperview];
    }
	[_buttons removeAllObjects];
    _pressedButton = nil;
    self.currentXOffset = 0.0;
}

- (UIButton *)buttonWithTag:(NSInteger)tag {
    UIView *view = [self.contentView viewWithTag:tag];
    if ([view isKindOfClass:[UIButton class]]) {
        return (UIButton *)view;
    }
    
    // if we get to this point that means there's still some
    // subview that isn't being assigned a non-conflicting tag
    WLog(@"%@", [view description]);
    
    return nil;
}

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0

- (void)addButton:(UIButton *)aButton shouldHighlight:(BOOL)shouldHighlight {
    // set standard display properties
	UIImage *stretchableButtonImage = [[UIImage imageNamed:MITImageNameScrollTabSelectedTab] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    
    CGFloat buttonYOffset = floor((self.frame.size.height - stretchableButtonImage.size.height) / 2);

    aButton.adjustsImageWhenHighlighted = shouldHighlight;
    
    if (shouldHighlight) {
        [aButton setBackgroundImage:nil forState:UIControlStateNormal];
        [aButton setBackgroundImage:stretchableButtonImage forState:UIControlStateHighlighted];
    }
    
    CGSize newSize = CGSizeZero;
    
    if ([aButton titleForState:UIControlStateNormal] != nil) {
        [aButton setTitleColor:[UIColor colorWithHexString:@"#E0E0E0"] forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        aButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        aButton.titleLabel.tag = BUTTON_TITLE_LABEL_TAG;
        aButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
        newSize = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];
    }
    
    UIImage *image = [aButton imageForState:UIControlStateNormal];
    if (image != nil) {
		aButton.imageEdgeInsets = UIEdgeInsetsMake(-1,0,0,0);
        newSize.width = image.size.width;// + 14.0;
        aButton.imageView.tag = BUTTON_IMAGE_TAG;
    }
    [aButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    newSize.width += SCROLL_TAB_HORIZONTAL_PADDING * 2 + SCROLL_TAB_HORIZONTAL_MARGIN;
    newSize.height = stretchableButtonImage.size.height;
    CGRect frame = aButton.frame;
    frame.size = newSize;
    frame.origin.x += _currentXOffset;
    frame.origin.y = buttonYOffset;
    aButton.frame = frame;
    _currentXOffset += frame.size.width;
    
    if (![_buttons containsObject:aButton]) {
        [_buttons addObject:aButton];
    }
    [_contentView addSubview:aButton];
    
    // update the content frame
    //if (_currentXOffset + SCROLL_TAB_HORIZONTAL_PADDING > _contentView.frame.size.width) {
        CGRect newFrame = _contentView.frame;
        newFrame.size.width = _currentXOffset + SCROLL_TAB_HORIZONTAL_PADDING;
        _contentView.frame = newFrame;
    //}
}


- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
    
    if (pressedButton.adjustsImageWhenHighlighted 
        && pressedButton != _pressedButton
        && [self.buttons containsObject:pressedButton]) {

        if (_pressedButton != nil) {
            [_pressedButton setTitleColor:[UIColor colorWithHexString:@"#E0E0E0"] forState:UIControlStateNormal];
            [_pressedButton setBackgroundImage:nil forState:UIControlStateNormal];
        }
        
        UIImage *buttonImage = [UIImage imageNamed:MITImageNameScrollTabSelectedTab];
        UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
        
        [pressedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [pressedButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];

        _pressedButton = pressedButton;
    }
    
    [self.navScrollerDelegate buttonPressed:sender];
}

- (void)sideButtonPressed:(id)sender {
	// This is a slight cheat. The bumpers scroll the next text button so it fits completely into view, 
	// but if all of the buttons in navbuttons are already in view, this scrolls by default to the far
	// left, where the search and bookmark buttons sit.
    CGPoint offset = self.scrollView.contentOffset;
	CGRect tabRect = CGRectMake(0, 0, 1, 1); // Because CGRectZero is ignored by -scrollRectToVisible:
	
    if (sender == self.leftScrollButton) {
        NSInteger i, count = [self.buttons count];
        for (i = count - 1; i >= 0; i--) {
            UIButton *tab = [self.buttons objectAtIndex:i];
            if (CGRectGetMinX(tab.frame) - offset.x < 0) {
                tabRect = tab.frame;
                tabRect.origin.x -= self.leftScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    } else if (sender == self.rightScrollButton) {
        for (UIButton *tab in self.buttons) {
            if (CGRectGetMaxX(tab.frame) - (offset.x + self.scrollView.frame.size.width) > 0) {
                tabRect = tab.frame;
                tabRect.origin.x += self.rightScrollButton.frame.size.width - 8.0;
                break;
            }
        }
    }
	[self.scrollView scrollRectToVisible:tabRect animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([scrollView isEqual:self.scrollView]) {
		CGPoint offset = scrollView.contentOffset;
		if (offset.x <= 0) {
			self.leftScrollButton.hidden = YES;
		} else {
			self.leftScrollButton.hidden = NO;
		}
		if (offset.x >= self.scrollView.contentSize.width - self.scrollView.frame.size.width) {
			self.rightScrollButton.hidden = YES;
		} else {
			self.rightScrollButton.hidden = NO;
		}
	}
}

- (void)dealloc {
    [_contentView release];
    [_scrollView release];
    [_buttons release];
    [super dealloc];
}

@end

