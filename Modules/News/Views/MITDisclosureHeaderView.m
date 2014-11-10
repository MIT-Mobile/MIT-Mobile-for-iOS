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
    
    self.titleLabel.text = @"";
    self.titleLabel.hidden = NO;

    self.accessoryView.hidden = NO;
}

@end
