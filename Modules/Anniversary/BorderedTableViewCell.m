#import "BorderedTableViewCell.h"

@implementation BorderedTableViewCell

@synthesize borderWidth;
@dynamic borderColor;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        borderWidth = 1.0;
        // draws border across bottom of cell
        borderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height - self.borderWidth, self.frame.size.width, self.borderWidth)];
        borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        borderView.backgroundColor = [UIColor greenColor];
        
        [self addSubview:borderView];
    }
    return self;
}

- (UIColor *)borderColor {
    return borderView.backgroundColor;
}

- (void)setBorderWidth:(CGFloat)newBorderWidth {
    borderWidth = newBorderWidth;
    CGRect frame = borderView.frame;
    frame.size.height = self.frame.size.height - borderWidth;
    borderView.frame = frame;
    [borderView setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)newBorderColor {
    borderView.backgroundColor = newBorderColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self bringSubviewToFront:borderView];
}

- (void)dealloc
{
    [borderView removeFromSuperview];
    [borderView release];
    [super dealloc];
}

@end
