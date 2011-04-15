#import <UIKit/UIKit.h>


@interface QRReaderOverlayView : UIView {
    BOOL _highlighted;
    CGRect _qrRect;
    UIColor *_highlightColor;
    UIColor *_outlineColor;
    UIColor *_overlayColor;
}

@property (nonatomic) BOOL highlighted;
@property (nonatomic,retain) UIColor *highlightColor;
@property (nonatomic,retain) UIColor *outlineColor;
@property (nonatomic,retain) UIColor *overlayColor;


- (CGRect)qrRect;
@end
