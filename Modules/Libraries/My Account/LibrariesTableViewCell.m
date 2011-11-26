#import "LibrariesTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

const CGFloat kLibrariesTableCellDefaultWidth = 290;

@interface LibrariesTableViewCell ()
- (void)privateInit;
@end

@implementation LibrariesTableViewCell
@synthesize contentViewInsets = _contentViewInsets,
            infoLabel = _infoLabel,
            itemDetails = _itemDetails,
            statusLabel = _statusLabel,
            statusIcon = _statusIcon,
            titleLabel = _titleLabel;

- (id)init
{
    return [self initWithReuseIdentifier:nil];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self) {
        [self privateInit];
    }

    return self;
}

- (void)privateInit
{
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.editingAccessoryType = UITableViewCellAccessoryNone;
    self.shouldIndentWhileEditing = NO;
    
    self.titleLabel = [[[UILabel alloc] init] autorelease];
    self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.titleLabel.highlightedTextColor = [UIColor whiteColor];
    self.titleLabel.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:self.titleLabel];
    
    self.infoLabel = [[[UILabel alloc] init] autorelease];
    self.infoLabel.lineBreakMode = UILineBreakModeTailTruncation;
    self.infoLabel.numberOfLines = 1;
    self.infoLabel.font = [UIFont systemFontOfSize:14.0];
    self.infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    self.infoLabel.highlightedTextColor = [UIColor whiteColor];
    self.infoLabel.autoresizingMask = UIViewAutoresizingNone;
    
    [self.contentView addSubview:self.infoLabel];
    
    self.statusLabel = [[[UILabel alloc] init] autorelease];
    self.statusLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont systemFontOfSize:14.0];
    self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    self.statusLabel.highlightedTextColor = [UIColor whiteColor];
    self.statusLabel.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:self.statusLabel];
    
    self.statusIcon = [[[UIImageView alloc] init] autorelease];
    self.statusIcon.hidden = YES;
    [self.contentView addSubview:self.statusIcon];
    
    self.contentViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

- (void)dealloc
{
    self.itemDetails = nil;
    self.infoLabel = nil;
    self.statusLabel = nil;
    self.titleLabel = nil;
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutContentUsingBounds:self.contentView.bounds];
}

- (void)layoutContentUsingBounds:(CGRect)viewBounds
{
    viewBounds = UIEdgeInsetsInsetRect(viewBounds, self.contentViewInsets);
    CGFloat viewWidth = CGRectGetWidth(viewBounds);
    
    {
        CGRect titleFrame = CGRectZero;
        titleFrame.origin = viewBounds.origin;
        titleFrame.size = [[self.titleLabel text] sizeWithFont:self.titleLabel.font
                                             constrainedToSize:CGSizeMake(viewWidth, CGFLOAT_MAX)
                                                 lineBreakMode:self.titleLabel.lineBreakMode];
        self.titleLabel.frame = titleFrame;
    }
    
    {
        
        CGRect infoFrame = CGRectZero;
        infoFrame.origin = CGPointMake(CGRectGetMinX(viewBounds),
                                       CGRectGetMaxY(self.titleLabel.frame) + 3.0);
        
        CGFloat constrainedHeight = (self.infoLabel.numberOfLines == 1) ? self.infoLabel.font.lineHeight : 2000.0;
        infoFrame.size = [[self.infoLabel text] sizeWithFont:self.infoLabel.font
                                           constrainedToSize:CGSizeMake(viewWidth, constrainedHeight)
                                               lineBreakMode:self.infoLabel.lineBreakMode];
        self.infoLabel.frame = infoFrame;
    }
    
    {
        CGRect iconFrame = CGRectZero;
        
        if (self.statusIcon.hidden == NO)
        {
            iconFrame.size = self.statusIcon.image.size;
            iconFrame.origin.x = CGRectGetMinX(viewBounds);
            iconFrame.origin.y = CGRectGetMaxY(self.infoLabel.frame) + 3.0;
            self.statusIcon.frame = iconFrame;
            
            // Add in some padding between the icon and the text that will follow
            iconFrame.size.width += 4.0;
        }
        
        CGRect statusFrame = CGRectZero;
        statusFrame.origin = CGPointMake(CGRectGetMinX(viewBounds) + iconFrame.size.width,
                                         CGRectGetMaxY(self.infoLabel.frame) + 3.0);
        statusFrame.size = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                               constrainedToSize:CGSizeMake(viewWidth - iconFrame.size.width, CGFLOAT_MAX)
                                                   lineBreakMode:self.statusLabel.lineBreakMode];
        self.statusLabel.frame = statusFrame;
    }
}

// This should not be called by cells in an actual tableview
- (CGFloat)heightForContentWithWidth:(CGFloat)width
{
    CGFloat height = 0;
    width -= self.contentViewInsets.left + self.contentViewInsets.right;
    
    {
        CGSize titleSize = [[self.titleLabel text] sizeWithFont:self.titleLabel.font
                                              constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                                  lineBreakMode:self.titleLabel.lineBreakMode];
        height += titleSize.height + 3.0;
    }
    
    {
        CGFloat constrainedHeight = (self.infoLabel.numberOfLines == 1) ? self.infoLabel.font.lineHeight : 2000.0;
        CGSize infoSize = [[self.infoLabel text] sizeWithFont:self.infoLabel.font
                                            constrainedToSize:CGSizeMake(width, constrainedHeight)
                                                lineBreakMode:self.infoLabel.lineBreakMode];
        height += infoSize.height + 3.0;
    }
    
    {
        CGSize iconSize = CGSizeZero;
        
        if (self.statusIcon.image && (self.statusIcon.hidden == NO))
        {
            iconSize = self.statusIcon.image.size;
            iconSize.width += 4.0;
        }
        
        CGSize statusSize = [[self.statusLabel text] sizeWithFont:self.statusLabel.font
                                                constrainedToSize:CGSizeMake(width - iconSize.width, CGFLOAT_MAX)
                                                    lineBreakMode:self.statusLabel.lineBreakMode];

        height += MAX(statusSize.height,iconSize.height) + 3.0;
    }
    
    return (height + self.contentViewInsets.top + self.contentViewInsets.bottom);
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
