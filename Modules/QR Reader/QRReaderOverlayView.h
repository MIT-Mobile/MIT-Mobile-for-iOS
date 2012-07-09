#import <UIKit/UIKit.h>


@interface QRReaderOverlayView : UIView

@property (nonatomic) BOOL highlighted;
@property (nonatomic,retain) UIColor *highlightColor;
@property (nonatomic,retain) UIColor *outlineColor;
@property (nonatomic,retain) UIColor *overlayColor;
@property (nonatomic,retain) NSString *helpText;


// Returns the rect in pixels. This rect is in this view's
// coordinate system
- (CGRect)qrRect;

// Returns the rect in normalized
//  image coordinates x->{0,1}, y->{0,1}
- (CGRect)normalizedCropRect;

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration;
@end
