#import <UIKit/UIKit.h>


@interface QRReaderOverlayView : UIView {
    BOOL _highlighted;
    CGRect _qrRect;
    UIColor *_highlightColor;
    UIColor *_outlineColor;
    UIColor *_overlayColor;
    UIInterfaceOrientation _interfaceOrientation;
    NSTimeInterval _animationDuration;
}

@property (nonatomic) BOOL highlighted;
@property (nonatomic,retain) UIColor *highlightColor;
@property (nonatomic,retain) UIColor *outlineColor;
@property (nonatomic,retain) UIColor *overlayColor;


// Returns the rect in pixels
- (CGRect)qrRect;

// Returns the rect in normalized
//  image coordinates x->{0,1}, y->{0,1}
- (CGRect)normalizedCropRect;

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration;
@end
