#import <Foundation/Foundation.h>
#import "LibrariesFinesSummaryView.h"

@interface LibrariesFinesSummaryView ()
@property (nonatomic,retain) UILabel *balanceLabel;
@property (nonatomic,retain) UILabel *infoLabel;
@end

@implementation LibrariesFinesSummaryView
@synthesize accountDetails = _accountDetails,
            edgeInsets = _edgeInsets;

@synthesize balanceLabel = _balanceLabel,
            infoLabel = _infoLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.balanceLabel = [[[UILabel alloc] init] autorelease];
        self.balanceLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        self.balanceLabel.backgroundColor = [UIColor clearColor];
        self.balanceLabel.lineBreakMode = UILineBreakModeTailTruncation;
        self.balanceLabel.text = @"";
        [self addSubview:self.balanceLabel];
        
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 2;
        self.infoLabel.backgroundColor = [UIColor clearColor];
        self.infoLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        
        self.infoLabel.text = @"";
        [self addSubview:self.infoLabel];

        self.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    return self;
}

- (void)dealloc
{
    self.accountDetails = nil;
    self.balanceLabel = nil;
    self.infoLabel = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.edgeInsets);
    
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
    CGFloat width = size.width - (self.edgeInsets.left + self.edgeInsets.right);
    CGFloat viewHeight = 0;
    
    CGSize textSize = [self.balanceLabel.text sizeWithFont:self.balanceLabel.font
                                         constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                             lineBreakMode:self.balanceLabel.lineBreakMode];
    viewHeight = textSize.height;
    
    
    textSize = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                               constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                   lineBreakMode:self.infoLabel.lineBreakMode];
    viewHeight += textSize.height;
    viewHeight += (self.edgeInsets.top + self.edgeInsets.bottom);
    
    return CGSizeMake(size.width, viewHeight);
}

- (void)setAccountDetails:(NSDictionary *)accountDetails
{
    [_accountDetails release];
    _accountDetails = [accountDetails retain];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    NSString *totalFines = [accountDetails objectForKey:@"balance"];
    if (totalFines)
    {
        self.balanceLabel.text = [NSString stringWithFormat:@"Balance as of %@: %@", dateString, totalFines];
        
        NSMutableString *string = [NSMutableString string];
        [string appendString:@"Payable at any MIT library service desk.\n"];
        [string appendString:@"TechCASH accepted only at Hayden Library."];
        self.infoLabel.text = string;
    }
    else
    {
        self.balanceLabel.text = @"";
    }
    
    [self setNeedsLayout];
}

@end
