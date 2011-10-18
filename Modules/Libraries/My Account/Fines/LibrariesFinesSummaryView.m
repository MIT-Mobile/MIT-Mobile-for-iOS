#import "LibrariesFinesSummaryView.h"

@interface LibrariesFinesSummaryView ()
@property (nonatomic,retain) UILabel *balanceLabel;
@property (nonatomic,retain) UILabel *infoLabel;
@end

@implementation LibrariesFinesSummaryView
@synthesize accountDetails = _accountDetails,
            balanceLabel = _balanceLabel,
            infoLabel = _infoLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.balanceLabel = [[[UILabel alloc] init] autorelease];
        self.balanceLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        self.balanceLabel.backgroundColor = [UIColor clearColor];
        self.balanceLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
        NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterNoStyle];
        self.balanceLabel.text = [NSString stringWithFormat:@"Balance as of %@: N/A", dateString];
        [self addSubview:self.balanceLabel];
        
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 2;
        self.infoLabel.backgroundColor = [UIColor clearColor];
        self.infoLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        
        NSMutableString *string = [NSMutableString string];
        [string appendString:@"Payable at any MIT library service desk.\n"];
        [string appendString:@"TechCASH accepted only at Hayden Library."];
        self.infoLabel.text = string;
        [self addSubview:self.infoLabel];
    }
    
    return self;
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
    {
        CGRect balanceRect = bounds;
        balanceRect.size = [self.balanceLabel.text sizeWithFont:self.balanceLabel.font
                                              constrainedToSize:bounds.size
                                                  lineBreakMode:self.balanceLabel.lineBreakMode];
        self.balanceLabel.frame = balanceRect;
    }

    {
        CGRect infoRect = bounds;
        infoRect.origin.y = CGRectGetMaxY(self.balanceLabel.frame);
        infoRect.size = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                                        constrainedToSize:bounds.size
                                            lineBreakMode:self.infoLabel.lineBreakMode];
        self.infoLabel.frame = infoRect;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize finalSize = CGSizeZero;
    finalSize.width = size.width;
    
    CGSize textSize = [self.balanceLabel.text sizeWithFont:self.balanceLabel.font
                                         constrainedToSize:size
                                             lineBreakMode:self.balanceLabel.lineBreakMode];
    finalSize.height = textSize.height;
    
    
    textSize = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                               constrainedToSize:size
                                   lineBreakMode:self.infoLabel.lineBreakMode];
    finalSize.height += textSize.height;
    finalSize.height += 5;
    return finalSize;
}

- (void)setAccountDetails:(NSDictionary *)accountDetails
{
    [_accountDetails release];
    _accountDetails = [accountDetails retain];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    NSString *totalFines = [accountDetails objectForKey:@"balance"];
    if (totalFines) {
        self.balanceLabel.text = [NSString stringWithFormat:@"Balance as of %@: %@", dateString, totalFines];
    } else {
        self.balanceLabel.text = [NSString stringWithFormat:@"Balance as of %@:", dateString];
    }
    
    [self setNeedsLayout];
}

@end
