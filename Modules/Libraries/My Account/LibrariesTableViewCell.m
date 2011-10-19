#import "LibrariesTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import <QuartzCore/QuartzCore.h>

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
        self.titleLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:self.titleLabel];
        
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 0;
        self.infoLabel.font = [UIFont systemFontOfSize:14.0];
        self.infoLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:self.infoLabel];
        
        self.statusLabel = [[[UILabel alloc] init] autorelease];
        self.statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.statusLabel.numberOfLines = 0;
        self.statusLabel.font = [UIFont systemFontOfSize:14.0];
        self.statusLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:self.statusLabel];
        
        self.statusIcon = [[[UIImageView alloc] init] autorelease];
        self.statusIcon.hidden = YES;
        [self.contentView addSubview:self.statusIcon];
        
        self.contentViewInsets = UIEdgeInsetsMake(5, 5, 5, 25);
        
        self.contentView.layer.borderColor = [[UIColor redColor] CGColor];
        self.contentView.layer.borderWidth = 2.0;
    }
    return self;
}

- (void)dealloc
{
    self.itemDetails = nil;
    self.infoLabel = nil;
    self.statusLabel = nil;
    self.statusIcon = nil;
    self.titleLabel = nil;
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentBounds = self.contentView.frame;
    contentBounds.origin = CGPointZero;
    self.contentView.bounds = CGRectMake(0,0,
                                         CGRectGetWidth(self.contentView.frame),
                                         CGRectGetHeight(self.contentView.frame));
    
    [self layoutContentUsingBounds:self.contentView.bounds];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    
    CGSize contentSize = newSize;
    // Subtract off the content view insets so we get the proper wrapping behavior
    contentSize.width -= (self.contentViewInsets.left + self.contentViewInsets.right);
    contentSize.height -= (self.contentViewInsets.top + self.contentViewInsets.bottom);
    
    contentSize = [self contentSizeThatFits:contentSize];
    
    // Add the contentView insets back in so we get the proper sizing for the cell
    contentSize.width += (self.contentViewInsets.left + self.contentViewInsets.right);
    contentSize.height += (self.contentViewInsets.top + self.contentViewInsets.bottom);
    return CGSizeMake(newSize.width, MAX(newSize.height,contentSize.height));
}


- (void)layoutContentUsingBounds:(CGRect)viewBounds
{
    CGFloat viewWidth = CGRectGetWidth(viewBounds);
    
    {
        CGRect titleFrame = viewBounds;
        titleFrame.size = [[self.titleLabel text] sizeWithFont:self.titleLabel.font
                                             constrainedToSize:CGSizeMake(viewWidth, CGFLOAT_MAX)
                                                 lineBreakMode:self.titleLabel.lineBreakMode];
        self.titleLabel.frame = titleFrame;
    }
    
    {
        CGRect infoFrame = CGRectZero;
        infoFrame.origin = CGPointMake(CGRectGetMinX(viewBounds),
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
        statusFrame.origin = CGPointMake(CGRectGetMinX(viewBounds) + statusInset,
                                         CGRectGetMaxY(self.infoLabel.frame));
        statusFrame.size = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                               constrainedToSize:CGSizeMake(viewWidth - statusInset, CGFLOAT_MAX)
                                                   lineBreakMode:self.statusLabel.lineBreakMode];
        self.statusLabel.frame = statusFrame;
    }
    
    if (self.statusIcon.hidden == NO) {
        CGRect imageFrame = CGRectZero;
        imageFrame.size = self.statusIcon.image.size;
        imageFrame.origin = CGPointMake(CGRectGetMinX(viewBounds),
                                        self.statusLabel.frame.origin.y);
        self.statusIcon.frame = imageFrame;
    }

}

- (CGSize)contentSizeThatFits:(CGSize)size
{
    CGFloat width = size.width;
    CGFloat height = size.height;
    
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
        if (self.statusIcon.hidden == NO) {
            statusInset = 3 + self.statusIcon.image.size.width;
        }
        
        CGSize noticeSize = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                                constrainedToSize:CGSizeMake(width - statusInset, CGFLOAT_MAX)
                                                    lineBreakMode:self.statusLabel.lineBreakMode];
        height += MAX(noticeSize.height,self.statusIcon.image.size.height);
    }
    
    return CGSizeMake(size.width, height);
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    if ([self.itemDetails isEqualToDictionary:itemDetails] == NO) {
        [_itemDetails release];
        _itemDetails = [itemDetails copy];
        
        if (itemDetails == nil) {
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
        
        [self setNeedsLayout];
    }
}
@end
