//
//  DiningHallMenuComparisonSectionHeaderView.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/22/13.
//
//

#import "DiningHallMenuComparisonSectionHeaderView.h"

@interface DiningHallMenuComparisonSectionHeaderView ()

@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UILabel * timeLabel;

@end

@implementation DiningHallMenuComparisonSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat halfHeight = CGRectGetHeight(frame) * 0.5f;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), halfHeight)];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(frame), halfHeight)];
        self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.timeLabel.backgroundColor = [UIColor darkGrayColor];
        self.timeLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.timeLabel];
    }
    return self;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.timeLabel.text = nil;
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
