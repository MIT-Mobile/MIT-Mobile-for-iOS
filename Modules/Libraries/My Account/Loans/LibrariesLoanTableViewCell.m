#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

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
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.editingAccessoryType = UITableViewCellAccessoryNone;

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

- (void)willTransitionToState:(UITableViewCellStateMask)state {
    // Before transitioning to editing:
    // - selectionView is totally invisible and hidden, so make it unhidden
    if (state & UITableViewCellStateShowingEditControlMask) {
        if (self.selectionView == nil) {
            self.selectionView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"libraries/cell-unselected"]] autorelease];
            
            CGRect frame = self.selectionView.frame;
            frame.origin.x = -30.0 + self.contentViewInsets.left;
            frame.origin.y = floor((CGRectGetHeight(self.contentView.bounds) - CGRectGetHeight(self.selectionView.frame)) / 2.0);
            self.selectionView.frame = frame;

            self.selectionStyle = UITableViewCellSelectionStyleNone;
            [self.contentView addSubview:self.selectionView];
            [self.contentView sendSubviewToBack:self.selectionView];
        }
    }

    [super willTransitionToState:state];
}

- (void)didTransitionToState:(UITableViewCellStateMask)state {
    // After transitioning away from editing:
    // - selectionView should be totally hidden, so remove it to free up memory
    if (!state & UITableViewCellStateShowingEditControlMask) {
        [self.selectionView removeFromSuperview];
        self.selectionView = nil;
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }

    // make sure the selection is cleared between renews
    self.selected = NO;
    [super didTransitionToState:state];
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
        self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
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
    if (self.selectionView) {
        // The checkmark image is 31px wide, but should really be 30px wide
        // to match the width of the accessory on the right.
        CGFloat leftSpace = 30.0 - self.contentViewInsets.left;
        CGRect selectionFrame = self.selectionView.frame;
        selectionFrame.origin.y = floor((CGRectGetHeight(bounds) - selectionFrame.size.height) / 2.0);
        
        if (self.editing) {
            // slide everything to the right as the accessory disappears
            selectionFrame.origin.x = 0.0;
            bounds.origin.x += leftSpace;
            bounds.size.width -= 30.0 - self.contentViewInsets.right;
        } else {
            // The checkbox starts out of view on the left
            selectionFrame.origin.x = -leftSpace;
            
        }
        
        self.selectionView.frame = selectionFrame;
    }
    
    [super layoutContentUsingBounds:bounds];
}

@end
