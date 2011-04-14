//
//  QRReaderOverlayView.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/11/11.
//  Copyright 2011 MIT. All rights reserved.
//

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
