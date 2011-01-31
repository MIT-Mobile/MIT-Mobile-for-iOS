#import <UIKit/UIKit.h>

@protocol NavScrollerDelegate

- (void)buttonPressed:(id)sender;

@end


@interface NavScrollerView : UIView <UIScrollViewDelegate>
{
    id<NavScrollerDelegate> navScrollerDelegate;
    
    UIScrollView *_scrollView;
    UIButton *_leftScrollButton;
    UIButton *_rightScrollButton;
    NSMutableArray *_buttons;
    UIButton *_pressedButton;
    UIView *_contentView;
    
    CGFloat _currentXOffset;
}

- (void)removeAllButtons;
- (UIButton *)buttonWithTag:(NSInteger)tag;
- (void)sideButtonPressed:(id)sender;
- (void)buttonPressed:(id)sender;
- (void)addButton:(UIButton *)button shouldHighlight:(BOOL)shouldHighlight;

@property (nonatomic, assign) id<NavScrollerDelegate> navScrollerDelegate;
@property (nonatomic, retain) NSMutableArray *buttons;
@property (nonatomic, retain) UIButton *leftScrollButton;
@property (nonatomic, retain) UIButton *rightScrollButton;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat currentXOffset;

@end

