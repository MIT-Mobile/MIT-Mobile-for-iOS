#import "HighlightTableViewCell.h"


@implementation HighlightTableViewCell
@synthesize highlightLabel = _highlightLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.autoresizesSubviews = YES;
        self.highlightLabel = [[HighlightLabel alloc] init];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)dealloc
{
    self.highlightLabel = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    
    frame.origin.x += 10;
    frame.size.width -= 20;
    
    if (self.accessoryView) {
        CGRect accFrame = self.accessoryView.frame;
        frame.size.width -= accFrame.size.width;
    } else if (self.accessoryType != UITableViewCellAccessoryNone) {
        frame.size.width -= 15;
    }
    
    self.highlightLabel.frame = frame;
    self.highlightLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight|
                              UIViewAutoresizingFlexibleWidth);
    [self.contentView addSubview:self.highlightLabel];
}

@end
