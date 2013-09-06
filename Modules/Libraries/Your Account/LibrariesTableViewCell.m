#import "LibrariesTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

const CGFloat kLibrariesTableCellDefaultWidth = 290;

@interface LibrariesTableViewCell ()
- (void)setup;
@end

@implementation LibrariesTableViewCell
- (id)init
{
    return [self initWithReuseIdentifier:nil];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }

    return self;
}

- (void)setup
{
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.editingAccessoryType = UITableViewCellAccessoryNone;
    self.shouldIndentWhileEditing = NO;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 0;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    infoLabel.numberOfLines = 1;
    infoLabel.font = [UIFont systemFontOfSize:14.0];
    infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    infoLabel.highlightedTextColor = [UIColor whiteColor];
    infoLabel.autoresizingMask = UIViewAutoresizingNone;
    
    [self.contentView addSubview:self.infoLabel];
    self.infoLabel = infoLabel;
    
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    statusLabel.numberOfLines = 0;
    statusLabel.font = [UIFont systemFontOfSize:14.0];
    statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    statusLabel.highlightedTextColor = [UIColor whiteColor];
    statusLabel.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:statusLabel];
    self.statusLabel = statusLabel;
    
    UIImageView *statusIcon = [[UIImageView alloc] init];
    statusIcon.hidden = YES;
    [self.contentView addSubview:statusIcon];
    self.statusIcon = statusIcon;
    
    self.contentViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
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
    if (![self.itemDetails isEqual:itemDetails]) {
        _itemDetails = [itemDetails copy];
        
        if (itemDetails == nil) {
            self.titleLabel.text = nil;
            self.infoLabel.text = nil;
            self.statusLabel.text = nil;
        } else {
            self.titleLabel.text = self.itemDetails[@"title"];
            
            NSString *author = self.itemDetails[@"author"];
            NSString *year = self.itemDetails[@"year"];
            self.infoLabel.text = [[NSString stringWithFormat:@"%@; %@",year,author] stringByDecodingXMLEntities];
        }
        
        [self setNeedsLayout];
    }
}
@end
