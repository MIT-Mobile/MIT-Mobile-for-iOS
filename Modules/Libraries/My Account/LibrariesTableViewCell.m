#import "LibrariesTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesTableViewCell
@synthesize contentViewInsets = _contentViewInsets,
            infoLabel = _infoLabel,
            itemDetails = _itemDetails,
            statusLabel = _statusLabel,
            statusIcon = _statusIcon,
            titleLabel = _titleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel = [[[UILabel alloc] init] autorelease];
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        [self.contentView addSubview:self.titleLabel];
        
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 0;
        self.infoLabel.font = [UIFont systemFontOfSize:14.0];
        [self.contentView addSubview:self.infoLabel];
        
        self.statusLabel = [[[UILabel alloc] init] autorelease];
        self.statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.statusLabel.numberOfLines = 0;
        self.statusLabel.font = [UIFont systemFontOfSize:14.0];
        [self.contentView addSubview:self.statusLabel];
        
        self.statusIcon = [[[UIImageView alloc] init] autorelease];
        self.statusIcon.hidden = YES;
        [self.contentView addSubview:self.statusIcon];
        
        self.contentViewInsets = UIEdgeInsetsMake(5, 5, 5, 25);
        
        [self addObserver:self
               forKeyPath:@"itemDetails"
                  options:(NSKeyValueObservingOptionInitial |
                           NSKeyValueObservingOptionNew |
                           NSKeyValueObservingOptionOld)
                  context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"itemDetails"];
    self.itemDetails = nil;
    self.infoLabel = nil;
    self.statusLabel = nil;
    self.statusIcon = nil;
    self.titleLabel = nil;
    
    [super dealloc];
}

- (void)layoutSubviewsWithEdgeInsets:(UIEdgeInsets)insets
{
    CGRect viewFrame = UIEdgeInsetsInsetRect(self.contentView.bounds, insets);
    CGFloat viewWidth = viewFrame.size.width;
    
    {
        CGRect titleFrame = viewFrame;
        titleFrame.size = [[self.titleLabel text] sizeWithFont:self.titleLabel.font
                                             constrainedToSize:CGSizeMake(viewWidth, CGFLOAT_MAX)
                                                 lineBreakMode:self.titleLabel.lineBreakMode];
        self.titleLabel.frame = titleFrame;
    }
    
    {
        CGRect infoFrame = CGRectZero;
        infoFrame.origin = CGPointMake(CGRectGetMinX(viewFrame),
                                       CGRectGetMaxY(self.titleLabel.frame) + 3);
        
        infoFrame.size = [[self.infoLabel text] sizeWithFont:self.infoLabel.font
                                           constrainedToSize:CGSizeMake(viewWidth, CGFLOAT_MAX)
                                               lineBreakMode:self.infoLabel.lineBreakMode];
        self.infoLabel.frame = infoFrame;
    }
    
    {
        CGFloat statusInset = 0.0;
        if (self.statusIcon.hidden == NO) {
            statusInset = 3 + self.statusIcon.image.size.width;
        }
        
        CGRect statusFrame = CGRectZero;
        statusFrame.origin = CGPointMake(CGRectGetMinX(viewFrame) + statusInset,
                                         CGRectGetMaxY(self.infoLabel.frame));
        statusFrame.size = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                               constrainedToSize:CGSizeMake(viewWidth - statusInset, CGFLOAT_MAX)
                                                   lineBreakMode:self.statusLabel.lineBreakMode];
        self.statusLabel.frame = statusFrame;
    }
    
    if (self.statusIcon.hidden == NO) {
        CGRect imageFrame = CGRectZero;
        imageFrame.size = self.statusIcon.image.size;
        imageFrame.origin = CGPointMake(CGRectGetMinX(viewFrame),
                                        self.statusLabel.frame.origin.y);
        self.statusIcon.frame = imageFrame;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutSubviewsWithEdgeInsets:self.contentViewInsets];
}

- (CGSize)sizeThatFits:(CGSize)size withEdgeInsets:(UIEdgeInsets)edgeInsets
{
    CGRect insetFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height),
                                              edgeInsets);
    
    CGFloat width = CGRectGetWidth(insetFrame);
    CGFloat height = fabsf(size.height - CGRectGetHeight(insetFrame));
    
    {
        CGSize titleSize = [[self.titleLabel text] sizeWithFont:self.titleLabel.font
                                              constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                                  lineBreakMode:self.titleLabel.lineBreakMode];
        height += titleSize.height + 3;
    }
    
    {
        CGSize infoSize = [[self.infoLabel text] sizeWithFont:self.infoLabel.font
                                            constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                                lineBreakMode:self.infoLabel.lineBreakMode];
        height += infoSize.height;
    }
    
    {
        CGFloat statusInset = 0.0;
        if (self.statusIcon.image) {
            statusInset = 3 + self.statusIcon.image.size.width;
        }
        
        CGSize noticeSize = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                                constrainedToSize:CGSizeMake(width - statusInset, CGFLOAT_MAX)
                                                    lineBreakMode:self.statusLabel.lineBreakMode];
        height += MAX(noticeSize.height,self.statusIcon.image.size.height);
    }
    
    return CGSizeMake(size.width, height);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    
    CGFloat contentWidth = newSize.width;
    
    if (self.accessoryView) {
        contentWidth -= self.accessoryView.frame.size.width;
    } else if (self.accessoryType != UITableViewCellAccessoryNone) {
        contentWidth -= 25;
    }
    
    CGSize contentSize = [self sizeThatFits:CGSizeMake(contentWidth, newSize.height)
                             withEdgeInsets:self.contentViewInsets];
    return CGSizeMake(newSize.width, MAX(newSize.height,contentSize.height));
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    if ([self.itemDetails isEqualToDictionary:itemDetails] == NO) {
        [self willChangeValueForKey:@"itemDetails"];
        
        [self->_itemDetails release];
        self->_itemDetails = [itemDetails copy];
        
        [self didChangeValueForKey:@"itemDetails"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"itemDetails"]) {
        if (self.itemDetails == nil) {
            self.titleLabel.text = nil;
            self.infoLabel.text = nil;
            self.statusLabel.text = nil;
            self.statusIcon.hidden = YES;
        } else {
            NSDictionary *item = self.itemDetails;
            self.titleLabel.text = [item objectForKey:@"title"];
            
            NSString *author = [item objectForKey:@"author"];
            NSString *year = [item objectForKey:@"year"];
            self.infoLabel.text = [[NSString stringWithFormat:@"%@; %@",year,author] stringByDecodingXMLEntities];
        }
        
        [self layoutSubviews];
    }
}
@end
