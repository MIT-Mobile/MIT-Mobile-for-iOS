#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LibrariesLoanSummaryView.h"
#import "UIKit+MITAdditions.h"

static NSString* kLibrariesLoanFormatString = @"You have %lu %@ on loan.";
static NSString* kLibrariesLoanOverdueFormatString = @"%lu %@ overdue.";

@interface LibrariesLoanSummaryView ()
@property (nonatomic,weak) UILabel* infoLabel;
@end

@implementation LibrariesLoanSummaryView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *infoLabel = [[UILabel alloc] init];
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.text = @"";
        infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        infoLabel.font = [UIFont systemFontOfSize:14.0];
        infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
        infoLabel.numberOfLines = 2;
        [self addSubview:infoLabel];
        self.infoLabel = infoLabel;
        
        
        UIButton *renewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [renewButton setTitle:@"Renew Books…"
                     forState:UIControlStateNormal];
        [renewButton setTitleColor:[UIColor colorWithWhite:0.19 alpha:1.0]
                          forState:UIControlStateNormal];
        [renewButton setTitleColor:[UIColor lightGrayColor]
                          forState:UIControlStateDisabled];
        renewButton.titleLabel.font = [UIFont systemFontOfSize:14.0];

        UIImage *buttonBackground = [[UIImage imageNamed:MITImageTabViewSummaryButton] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        [renewButton setBackgroundImage:buttonBackground forState:UIControlStateNormal];
        renewButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 3.0, 0.0, -3.0);

        CGRect buttonFrame = renewButton.frame;
        buttonFrame.size = CGSizeMake(118.0, 35.0);
        renewButton.frame = buttonFrame;
        [self addSubview:renewButton];
        self.renewButton = renewButton;
        
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
        CGRect buttonFrame = self.renewButton.frame;
        buttonFrame.origin.x = CGRectGetMaxX(bounds) - buttonFrame.size.width;
        buttonFrame.origin.y = floor((CGRectGetHeight(self.bounds) - buttonFrame.size.height) / 2.0);
        self.renewButton.frame = buttonFrame;
        
        bounds.size.width -= CGRectGetWidth(self.renewButton.frame);
    }
    
    {
        CGRect titleFrame = bounds;
        titleFrame.size = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                                          constrainedToSize:bounds.size
                                              lineBreakMode:self.infoLabel.lineBreakMode];
        self.infoLabel.frame = titleFrame;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat width = size.width - (self.edgeInsets.left + self.renewButton.frame.size.width + self.edgeInsets.right);
    CGSize contentSize = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                                         constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                             lineBreakMode:self.infoLabel.lineBreakMode];
    
    CGFloat frameHeight = CGRectGetHeight(self.renewButton.frame);
    CGFloat height = MAX(contentSize.height,frameHeight);
    height += (self.edgeInsets.top + self.edgeInsets.bottom);
    return CGSizeMake(size.width, height);
}

- (void)setAccountDetails:(NSDictionary *)accountDetails
{
    _accountDetails = [accountDetails copy];

    NSUInteger loanCount = [accountDetails[@"total"] unsignedIntegerValue];
    NSUInteger overdueCount = [accountDetails[@"overdue"] unsignedIntegerValue];
    
    NSMutableString *infoText = [NSMutableString stringWithFormat:kLibrariesLoanFormatString, loanCount, ((loanCount == 1) ? @"item" : @"items")];
    
    if (overdueCount > 0)
    {
        // highly unlikely this will ever be false, but it's best to be careful
        [infoText appendFormat:(loanCount < 1000) ? @"\n" : @" "];

        [infoText appendFormat:kLibrariesLoanOverdueFormatString, overdueCount, ((overdueCount == 1) ? @"is" : @"are")];
    }
    
    self.infoLabel.text = infoText;

    [self setNeedsLayout];
}
@end
