#import "MultiControlCell.h"


@implementation MultiControlCell

@synthesize controls, horizontalSpacing, margins, position;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.controls = nil;
        self.horizontalSpacing = 0.0;
        self.margins = CGSizeMake(0.0, 0.0);
        self.position = 0;
    }
    return self;
}

- (void)setControls:(NSArray *)newControls {
    for (UIControl *control in controls) {
        [control removeFromSuperview];
    }
    [controls release];
    controls = [newControls retain];
    for (UIControl *control in controls) {
        [self.contentView addSubview:control];
    }
    [self setNeedsLayout];
}

- (void)setHorizontalSpacing:(CGFloat)newHorizontalSpacing {
    horizontalSpacing = newHorizontalSpacing;
    [self setNeedsLayout];
}

- (void)setMargins:(CGSize)newMargins {
    margins = newMargins;
    [self setNeedsLayout];
}

- (void)setPosition:(NSInteger)newPosition {
    position = newPosition;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat xOffset = self.margins.width;
    CGFloat yOffset = (position == 0) ? self.margins.height : 0;
    NSInteger i = 0;
    NSInteger last = [controls count] - 1;
    for (UIControl *control in controls) {
        CGRect frame = control.frame;
        if (i < last) {
            frame.origin.x = round(xOffset);
        } else {
            // explicitly make the last button flush right
            frame.origin.x = self.frame.size.width - (frame.size.width + self.margins.width);
        }
        frame.origin.y = round(yOffset);
        xOffset += frame.size.width + horizontalSpacing;
        control.frame = frame;
        i++;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [super dealloc];
}

@end
