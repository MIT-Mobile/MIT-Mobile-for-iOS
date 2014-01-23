//
//  PeopleDetailsHeaderView.m
//  MIT Mobile
//
//  Created by Austin Emmons on 1/10/14.
//
//

#import "PeopleDetailsHeaderView.h"

@implementation PeopleDetailsHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    CGFloat topPadding = CGRectGetMinY(self.primaryLabel.frame);
    CGFloat bottomPadding = frame.size.height - CGRectGetMaxY(self.secondaryLabel.frame);
    if (bottomPadding < topPadding) {
        
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
