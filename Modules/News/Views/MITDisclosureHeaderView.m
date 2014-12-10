#import "MITDisclosureHeaderView.h"

@interface MITDisclosureHeaderView ()

@end

@implementation MITDisclosureHeaderView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 1;
        [self.contentView addSubview:label];
        self->_titleLabel = label;

        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageDisclosureRight]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:imageView];
        self->_accessoryView = imageView;

        NSDictionary *views = @{@"accessoryView" : _accessoryView,
                                @"titleLabel" : _titleLabel};

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[titleLabel]-[accessoryView]"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[accessoryView]-(>=0)-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];

    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        if (_highlighted) {
            self.highlightingView.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1];
        } else {
            self.highlightingView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.highlighted = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.highlighted = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.highlighted = NO;
}

@end
