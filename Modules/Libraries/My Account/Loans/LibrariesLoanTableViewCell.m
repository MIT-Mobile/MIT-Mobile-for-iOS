#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"

@interface LibrariesLoanTableViewCell ()
@property (nonatomic, retain) UIImageView *selectionView;
@end

@implementation LibrariesLoanTableViewCell
@synthesize selectionView = _selectionView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.editingAccessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = UITableViewCellAccessoryNone;

        self.selectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"libraries/cell-unselected"]] autorelease];
        [self.contentView addSubview:self.selectionView];
        
        self.statusIcon.image = [UIImage imageNamed:@"libraries/status-alert"];
        self.statusIcon.hidden = YES;
    }
    
    return self;
}

- (void)dealloc
{
    self.selectionView = nil;
    [super dealloc];
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

    self.selectionView.hidden = !editing;
    [self setNeedsLayout];
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    [super setItemDetails:itemDetails];
    
    NSMutableString *status = [NSMutableString string];
    if ([[itemDetails objectForKey:@"has-hold"] boolValue]) {
        [status appendString:@"Item has holds\n"];
    }
    
    if ([[itemDetails objectForKey:@"overdue"] boolValue]) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusIcon.hidden = NO;
    } else {
        self.statusLabel.textColor = [UIColor blackColor];
        self.statusIcon.hidden = YES;
    }
    
    NSString *dueText = [itemDetails objectForKey:@"dueText"];
    
    if (dueText) {
        [status appendString:dueText];
    }
    
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
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
