#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LibrariesLoanSummaryView.h"
#import "UIKit+MITAdditions.h"

static NSString* kLibrariesLoanFormatString = @"You have %lu %@ on loan.";
static NSString* kLibrariesLoanOverdueFormatString = @"%lu %@ overdue.";

@interface LibrariesLoanSummaryView ()
@property (nonatomic, retain) UILabel* infoLabel;
@end

@implementation LibrariesLoanSummaryView
@synthesize accountDetails = _accountDetails,
            edgeInsets = _edgeInsets;
@synthesize infoLabel = _infoLabel;
@synthesize renewButton = _renewButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.backgroundColor = [UIColor clearColor];
        self.infoLabel.text = @"";
        self.infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        self.infoLabel.font = [UIFont systemFontOfSize:14.0];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 2;
        [self addSubview:self.infoLabel];
        
        
        self.renewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self.renewButton setTitle:@"Renew Books…"
                          forState:UIControlStateNormal];
        [self.renewButton setTitleColor:[UIColor colorWithWhite:0.19 alpha:1.0]
                               forState:UIControlStateNormal];
        [self.renewButton setTitleColor:[UIColor lightGrayColor]
                               forState:UIControlStateDisabled];
        self.renewButton.titleLabel.font = [UIFont systemFontOfSize:14.0];

        UIImage *buttonBackground = [[UIImage imageNamed:@"global/tab2-summary-button"]
                                     stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        [self.renewButton setBackgroundImage:buttonBackground forState:UIControlStateNormal];
        self.renewButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 3.0, 0.0, -3.0);

        CGRect buttonFrame = self.renewButton.frame;
        buttonFrame.size = CGSizeMake(118.0, 35.0);
        self.renewButton.frame = buttonFrame;
        
        [self addSubview:self.renewButton];
        
        self.edgeInsets = UIEdgeInsetsMake(6, 10, 9, 10);
    }
    return self;
}

- (void)dealloc
{
    self.infoLabel = nil;
    self.accountDetails = nil;

    [super dealloc];
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
    [_accountDetails release];
    _accountDetails = [accountDetails retain];

    NSUInteger loanCount = [[accountDetails objectForKey:@"total"] unsignedIntegerValue];
    NSUInteger overdueCount = [[accountDetails objectForKey:@"overdue"] unsignedIntegerValue];
    
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
