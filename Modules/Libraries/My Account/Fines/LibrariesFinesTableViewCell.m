#import <QuartzCore/QuartzCore.h>
#import "LibrariesFinesTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@implementation LibrariesFinesTableViewCell
@synthesize fineLabel = _fineLabel;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.fineLabel = [[[UILabel alloc] init] autorelease];
        self.fineLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.fineLabel.numberOfLines = 1;
        self.fineLabel.font = [UIFont systemFontOfSize:17.0];
        self.fineLabel.textColor = [UIColor blackColor];
        self.fineLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:self.fineLabel];
        
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
    
    NSMutableString *status = [NSMutableString string];
    NSTimeInterval fineInterval = [[itemDetails objectForKey:@"fine-date"] doubleValue];
    NSDate *fineDate = [NSDate dateWithTimeIntervalSince1970:fineInterval];
    [status appendFormat:@"Fined %@", [NSDateFormatter localizedStringFromDate:fineDate
                                                                     dateStyle:NSDateFormatterShortStyle
                                                                     timeStyle:NSDateFormatterNoStyle]];
    
    self.statusLabel.textColor = [UIColor colorWithHexString:@"#404649"];
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
    
    self.fineLabel.text= [itemDetails objectForKey:@"display-amount"];
}

@end
