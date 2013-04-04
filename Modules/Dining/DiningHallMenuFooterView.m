//
//  DiningHallMenuFooterView.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/4/13.
//
//

#import "DiningHallMenuFooterView.h"

@interface DiningHallMenuFooterView ()

@end

@implementation DiningHallMenuFooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
        view.userInteractionEnabled = NO;
        view.frame = CGRectInset(self.frame, 20, 0);
        
        [view setImage:[UIImage imageNamed:@"icons/home-about"] forState:UIControlStateNormal];
        [view setTitle:@"Rotate device to compare venues" forState:UIControlStateNormal];
        view.titleLabel.font = [UIFont systemFontOfSize:13.0];
        view.titleLabel.textColor = [UIColor darkTextColor];
        
        view.center = CGPointMake(floor(CGRectGetWidth(self.bounds) * 0.5), floor(CGRectGetHeight(self.bounds) * 0.5));
        
        [self addSubview:view];
    }
    return self;
}

@end
