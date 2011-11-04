#import "LibrariesRenewTableViewCell.h"

@interface LibrariesRenewTableViewCell ()
@property (nonatomic,retain) UIImageView *selectionView;
@end

@implementation LibrariesRenewTableViewCell
@synthesize selectionView = _selectionView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"libraries/cell-unselected"]] autorelease];
        [self.contentView addSubview:self.selectionView];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.editingAccessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected != selected)
    {
        if (selected)
        {
            self.selectionView.image = [UIImage imageNamed:@"libraries/cell-selected"];
        }
        else
        {
            self.selectionView.image = [UIImage imageNamed:@"libraries/cell-unselected"];
        }
    }
    
    [super setSelected:selected animated:animated];
    [self setNeedsLayout];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        self.selectionView.hidden = NO;
    }
    else
    {
        self.selectionView.hidden = YES;
    }
    [self setNeedsLayout];
}

- (void)layoutContentUsingBounds:(CGRect)bounds
{
    if (self.isEditing)
    {
        CGRect selectionFrame = CGRectZero;
        selectionFrame.size = self.selectionView.image.size;
        selectionFrame.origin = CGPointMake(bounds.origin.x,
                                            floor((CGRectGetHeight(bounds) - selectionFrame.size.height) / 2.0));
        self.selectionView.frame = selectionFrame;
        
        bounds = CGRectMake(bounds.origin.x + CGRectGetWidth(selectionFrame),
                            bounds.origin.y,
                            CGRectGetWidth(bounds) - CGRectGetWidth(selectionFrame),
                            CGRectGetHeight(bounds));
    }
    
    [super layoutContentUsingBounds:bounds];
}

- (CGFloat)heightForContentWithWidth:(CGFloat)width
{
    if (self.isEditing)
    {
        width -= self.selectionView.image.size.width;
    }
    
    return [super heightForContentWithWidth:width];
}
@end
