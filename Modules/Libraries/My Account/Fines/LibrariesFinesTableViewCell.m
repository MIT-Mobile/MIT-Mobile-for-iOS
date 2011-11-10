#import <QuartzCore/QuartzCore.h>
#import "LibrariesFinesTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesFinesTableViewCell
@synthesize fineLabel = _fineLabel;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.fineLabel = [[[UILabel alloc] init] autorelease];
        self.fineLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.fineLabel.numberOfLines = 1;
        self.fineLabel.font = [UIFont boldSystemFontOfSize:17.0];
        self.fineLabel.textColor = [UIColor redColor];
        [self.contentView addSubview:self.fineLabel];
    }
    
    return self;
}

- (void)layoutContentUsingBounds:(CGRect)bounds
{
    {
        CGRect fineFrame = CGRectZero;
        fineFrame.size = [[self.fineLabel text] sizeWithFont:self.fineLabel.font];
        fineFrame.origin = CGPointMake(CGRectGetMaxX(bounds) - fineFrame.size.width,
                                       CGRectGetMinY(bounds));
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
    
    self.statusLabel.textColor = [UIColor blackColor];            
    self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
    
    self.fineLabel.text = [itemDetails objectForKey:@"display-amount"];
}

@end
