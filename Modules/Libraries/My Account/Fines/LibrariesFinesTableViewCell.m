#import <QuartzCore/QuartzCore.h>
#import "LibrariesFinesTableViewCell.h"
#import "Foundation+MITAdditions.h"

@implementation LibrariesFinesTableViewCell
@synthesize fineLabel = _fineLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style
                reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fineLabel = [[[UILabel alloc] init] autorelease];
        self.fineLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.fineLabel.numberOfLines = 1;
        self.fineLabel.font = [UIFont boldSystemFontOfSize:17.0];
        self.fineLabel.textColor = [UIColor redColor];
        [self.contentView addSubview:self.fineLabel];
        
        self.statusIcon.image = nil;
    }
    
    return self;
}

- (void)layoutSubviewsWithEdgeInsets:(UIEdgeInsets)insets
{
    CGRect viewFrame = UIEdgeInsetsInsetRect(self.contentView.bounds, insets);
    UIEdgeInsets modifiedInsets = insets;
    
    {
        CGRect fineFrame = CGRectZero;
        fineFrame.size = [[self.fineLabel text] sizeWithFont:self.fineLabel.font];
        fineFrame.origin = CGPointMake(CGRectGetMaxX(viewFrame) - fineFrame.size.width,
                                       CGRectGetMaxY(viewFrame) - fineFrame.size.height);
        self.fineLabel.frame = fineFrame;
    }
    
    modifiedInsets.right += self.fineLabel.frame.size.width + 4;
    
    [super layoutSubviewsWithEdgeInsets:modifiedInsets];
}

- (CGSize)sizeThatFits:(CGSize)size withEdgeInsets:(UIEdgeInsets)edgeInsets
{
    CGSize fineSize = [[self.fineLabel text] sizeWithFont:self.fineLabel.font];
    
    edgeInsets.right += fineSize.width;
    
    return [super sizeThatFits:size
                withEdgeInsets:edgeInsets];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"itemDetails"]) {
        NSDictionary *item = self.itemDetails;
        if (item == nil) {
            self.fineLabel.text = nil;
        } else {
            
            NSMutableString *status = [NSMutableString string];
            NSTimeInterval fineInterval = [[item objectForKey:@"fine-date"] doubleValue];
            NSDate *fineDate = [NSDate dateWithTimeIntervalSince1970:fineInterval];
            [status appendFormat:@"Fined %@", [NSDateFormatter localizedStringFromDate:fineDate
                                                                             dateStyle:NSDateFormatterShortStyle
                                                                             timeStyle:NSDateFormatterNoStyle]];
            self.statusIcon.hidden = YES;
            self.statusLabel.textColor = [UIColor blackColor];            
            self.statusLabel.text = [[status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
            
            self.fineLabel.text = [item objectForKey:@"display-amount"];
        }
    }
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
