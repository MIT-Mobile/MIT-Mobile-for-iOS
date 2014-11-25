#import "MITNewsLoadMoreCollectionViewCell.h"

@implementation MITNewsLoadMoreCollectionViewCell

- (void)commonInit
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1 ) {
        [[self contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

@end
