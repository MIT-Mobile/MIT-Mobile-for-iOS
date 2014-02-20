#import "MITDisclosureHeaderView.h"

@interface MITDisclosureHeaderView ()

@end

@implementation MITDisclosureHeaderView
@synthesize textLabel = _textLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 1;
        [self.contentView addSubview:label];
        self->_textLabel = label;

        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"news/news_chevron_small"]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:imageView];
        self->_accessoryView = imageView;

        NSDictionary *views = @{@"accessoryView" : _accessoryView,
                                @"textLabel" : _textLabel};

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[textLabel]-[accessoryView]"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|"
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
    
    self.textLabel.text = @"";
    self.textLabel.hidden = NO;

    self.accessoryView.hidden = NO;
}
@end
