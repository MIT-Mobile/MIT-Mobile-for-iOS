#import <QuartzCore/QuartzCore.h>
#import "LibrariesFinesTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@implementation LibrariesFinesTableViewCell
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *fineLabel = [[UILabel alloc] init];
        fineLabel.lineBreakMode = NSLineBreakByWordWrapping;
        fineLabel.numberOfLines = 1;
        fineLabel.font = [UIFont systemFontOfSize:17.0];
        fineLabel.textColor = [UIColor blackColor];
        fineLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:fineLabel];
        self.fineLabel = fineLabel;
        
        self.statusIcon.hidden = YES;
    }
    
    return self;
}

- (void)layoutContentUsingBounds:(CGRect)bounds
{
    {
        CGRect fineBounds = UIEdgeInsetsInsetRect(bounds, self.contentViewInsets);
        CGRect fineFrame = CGRectZero;
        fineFrame.size = [[self.fineLabel text] sizeWithFont:self.fineLabel.font];
        fineFrame.origin = CGPointMake(CGRectGetMaxX(fineBounds) - fineFrame.size.width,
                                       CGRectGetMinY(fineBounds));
        self.fineLabel.frame = fineFrame;
        bounds.size.width -= (CGRectGetWidth(fineFrame) + 5.0);
    }
    
    [super layoutContentUsingBounds:bounds];
}

- (CGFloat)heightForContentWithWidth:(CGFloat)width
{
    CGSize fineSize = [[self.fineLabel text] sizeWithFont:self.fineLabel.font];

    return [super heightForContentWithWidth:(width - (fineSize.width + 5.0))];
}

- (void)setItemDetails:(NSDictionary *)itemDetails
{
    [super setItemDetails:itemDetails];
    
    NSTimeInterval fineInterval = [itemDetails[@"fine-date"] doubleValue];
    NSDate *fineDate = [NSDate dateWithTimeIntervalSince1970:fineInterval];
    NSString *status =  [NSString stringWithFormat:@"Fined %@", [NSDateFormatter localizedStringFromDate:fineDate
                                                                                               dateStyle:NSDateFormatterShortStyle
                                                                                               timeStyle:NSDateFormatterNoStyle]];
    
    self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
    self.fineLabel.text = itemDetails[@"display-amount"];
}

@end
