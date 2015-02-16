#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MITCalloutArrowDirection) {
    MITCalloutArrowDirectionNone   = 0,
    MITCalloutArrowDirectionTop    = 1,
    MITCalloutArrowDirectionLeft   = 1 << 1,
    MITCalloutArrowDirectionBottom = 1 << 2,
    MITCalloutArrowDirectionRight  = 1 << 3
};

extern NSInteger const MITCalloutPermittedArrowDirectionAny;

@class MITCalloutView;

@protocol MITCalloutViewDelegate <NSObject>
/**
 *  Used to notify the delegate when the callout is forced to position outside of the constraining view
 *
 *  @param calloutView     the view that is positioned offscreen
 *  @param offscreenOffset a CGPoint indicating the offset from screen ie: {-4,-8} is 4 pts left, and 8 points above the constraining view.  {10, 5} is 10 points to the right and 5 points below the constraining view
 */
- (void)calloutView:(MITCalloutView *)calloutView positionedOffscreenWithOffset:(CGPoint)offscreenOffset;

/**
 *  Called when the callout has been tapped
 *
 *  @param calloutView the callout that was tapped
 */
- (void)calloutViewTapped:(MITCalloutView *)calloutView;

/**
 *  Called when the callout is removed from the view hierarchy.
 *
 *  @param calloutView the callout that was removed
 */
- (void)calloutViewRemovedFromViewHierarchy:(MITCalloutView *)calloutView;
@end

@interface MITCalloutView : UIView

/**
 *  Callout delegate
 */
@property (nonatomic, weak) id<MITCalloutViewDelegate>delegate;

/**
 *  In default context, this sets the title text
 */
@property (nonatomic, copy) NSString *titleText;
/**
 *  In default context, this sets the subtitle text
 */
@property (nonatomic, copy) NSString *subtitleText;
/**
 *  Override default content view w/ custom UIView
 */
@property (nonatomic, strong) UIView *contentView;

/**
 *  When drawing the content view, these will indicate distance from each side
 */
@property (nonatomic) UIEdgeInsets internalInsets;
/**
 *  Wehn positioning the popover, these are the distances from the constraining view to position
 */
@property (nonatomic) UIEdgeInsets externalInsets;

/**
 *  Whether or not to highlight in response to user touch.  Defaults to YES.
 */
@property (nonatomic) BOOL shouldHighlightOnTouch;

/**
 *  The current arrow direction of the callout
 */
@property (nonatomic, readonly) MITCalloutArrowDirection currentArrowDirection;

/**
 *  The available arrow directions declared w/ bitwise or -- MITCalloutArrowDirectionTop | MITCalloutArrowDirectionBottom
 *  @default - MITCalloutPermittedArrowDirectionAny
 */
@property (nonatomic) NSInteger permittedArrowDirections;

/**
 *  If the constraining view has changed, and you want the callout to readjust itself based on new parameters.
 */
- (void)updatePresentation;

/**
 *  Present the callout
 *
 *  @param rect the rectangle to position off of
 *  @param view the view to add the callout and constrain it within
 */
- (void)presentFromRect:(CGRect)presentationRect inView:(UIView *)view;

/**
 *  Present the callout
 *
 *  @param rect             the rectangle to position off of
 *  @param view             the view to add the callout to
 *  @param constrainingView the view to constrain the callout positioning
 */
- (void)presentFromRect:(CGRect)presentationRect inView:(UIView *)view withConstrainingView:(UIView *)constrainingView;

/**
 *  Dismiss the callout
 */
- (void)dismissCallout;

@end
