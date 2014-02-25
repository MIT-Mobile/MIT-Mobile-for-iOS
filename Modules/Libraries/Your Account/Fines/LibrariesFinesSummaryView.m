#import <Foundation/Foundation.h>
#import "LibrariesFinesSummaryView.h"
#import "UIKit+MITAdditions.h"

@interface LibrariesFinesSummaryView ()
@property (nonatomic,weak) UILabel *balanceLabel;
@property (nonatomic,weak) UILabel *infoLabel;
@end

@implementation LibrariesFinesSummaryView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *balanceLabel = [[UILabel alloc] init];
        balanceLabel.font = [UIFont boldSystemFontOfSize:17.0];
        balanceLabel.backgroundColor = [UIColor clearColor];
        balanceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        balanceLabel.text = @"";
        [self addSubview:balanceLabel];
        self.balanceLabel = balanceLabel;
        
        UILabel *infoLabel = [[UILabel alloc] init];
        infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
        infoLabel.numberOfLines = 2;
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        infoLabel.font = [UIFont systemFontOfSize:14.0];
        infoLabel.text = @"Payable at any MIT library service desk." "\n"
                               "TechCASH accepted only at Hayden Library.";
        [self addSubview:infoLabel];
        self.infoLabel = infoLabel;

        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            self.edgeInsets = UIEdgeInsetsMake(6, 15, 9, 15);
        } else {
            self.edgeInsets = UIEdgeInsetsMake(6, 10, 9, 10);
        }
    }
    
    return self;
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
    _accountDetails = [accountDetails copy];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    NSString *totalFines = nil;
    if ([accountDetails[@"balance"] length]) {
        totalFines = accountDetails[@"balance"];
    } else {
        totalFines = @"";
    }
    
    self.balanceLabel.text = [NSString stringWithFormat:@"Balance as of %@: %@", dateString, totalFines];
    
    [self setNeedsLayout];
}

@end
