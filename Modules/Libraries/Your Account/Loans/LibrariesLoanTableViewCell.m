#import <QuartzCore/QuartzCore.h>
#import "LibrariesLoanTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesLoanTableViewCell ()
@property (nonatomic, weak) UIImageView *selectionView;
@end

@implementation LibrariesLoanTableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.editingAccessoryType = UITableViewCellAccessoryNone;

        self.statusIcon.image = [UIImage imageNamed:MITImageLibrariesStatusAlert];
        self.statusIcon.hidden = YES;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected != selected)
    {
        if (selected) {
            UIImage *image = [[UIImage imageNamed:MITImageLibrariesCheckmarkSelected] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.selectionView.tintColor = [UIColor mit_tintColor];
            self.selectionView.image = image;
        } else {
            UIImage *image = [[UIImage imageNamed:MITImageLibrariesCheckmark] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.selectionView.tintColor = [UIColor lightGrayColor];
            self.selectionView.image = image;
        }
    }

    [super setSelected:selected animated:animated];
    [self setNeedsLayout];
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
    // Before transitioning to editing:
    // - selectionView is totally invisible and hidden, so make it unhidden
    if (state & UITableViewCellStateShowingEditControlMask) {
        if (!self.selectionView) {
            NSString *imageName = @"libraries-cell-unselected";
            UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            UIImageView *selectionView = [[UIImageView alloc] initWithImage:image];
            selectionView.alpha = 0.0;
            
            CGRect frame = selectionView.frame;
            frame.origin.x = -30.0 + self.contentViewInsets.left;
            frame.origin.y = floor((CGRectGetHeight(self.contentView.bounds) - CGRectGetHeight(selectionView.frame)) / 2.0);

            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                selectionView.tintColor = [UIColor lightGrayColor];
                frame.origin.x -= 18.;
            }

            selectionView.frame = frame;

            self.selectionStyle = UITableViewCellSelectionStyleNone;
            [self.contentView addSubview:selectionView];
            [self.contentView sendSubviewToBack:selectionView];
            self.selectionView = selectionView;
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
    if ([itemDetails[@"has-hold"] boolValue]) {
        [status appendString:@"Item has holds\n"];
    }
    
    if ([itemDetails[@"overdue"] boolValue]) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusIcon.hidden = NO;
    } else {
        self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        self.statusIcon.hidden = YES;
    }
    
    NSString *dueText = itemDetails[@"dueText"];
    
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
        CGFloat accessoryWidth = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 33. : 20;
        CGFloat indentWidth = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 15. : 10;
        CGFloat leftSpace = accessoryWidth + indentWidth - self.contentViewInsets.left;
        CGRect selectionFrame = self.selectionView.frame;
        selectionFrame.origin.y = floor((CGRectGetHeight(bounds) - selectionFrame.size.height) / 2.0);
        
        if (self.editing) {
            // slide everything to the right as the accessory disappears
            self.selectionView.alpha = 1.0;
            selectionFrame.origin.x = floor((accessoryWidth + indentWidth - selectionFrame.size.width) / 2.0);
            bounds.origin.x += leftSpace;
            bounds.size.width -= accessoryWidth + indentWidth - self.contentViewInsets.right;
        } else {
            // The checkbox starts out of view on the left
            self.selectionView.alpha = 0.0;
            selectionFrame.origin.x = -leftSpace + floor((accessoryWidth + indentWidth - selectionFrame.size.width) / 2.0);
            
        }
        
        self.selectionView.frame = selectionFrame;
        
        if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
            UIEdgeInsets insets = self.separatorInset;
            insets.left = 48.;
            self.separatorInset = insets;
        }
    } else {
        if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
            UIEdgeInsets insets = self.separatorInset;
            insets.left = 15.;
            self.separatorInset = insets;
        }
    }
    
    [super layoutContentUsingBounds:bounds];
}

@end
