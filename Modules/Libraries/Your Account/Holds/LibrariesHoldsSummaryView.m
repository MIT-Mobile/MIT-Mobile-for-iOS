#import "LibrariesHoldsSummaryView.h"
#import "UIKit+MITAdditions.h"

static NSString* kLibrariesHoldsStatusText = @"You have %ld hold %@.";
static NSString* kLibrariesHoldsPickupText = @"\n%ld %@ ready for pickup.";

@interface LibrariesHoldsSummaryView ()
@property (nonatomic,retain) UILabel *infoLabel;
@end

@implementation LibrariesHoldsSummaryView
@synthesize accountDetails = _accountDetails,
            edgeInsets = _edgeInsets;

@synthesize infoLabel = _infoLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.infoLabel = [[[UILabel alloc] init] autorelease];
        self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.infoLabel.numberOfLines = 2;
        self.infoLabel.backgroundColor = [UIColor clearColor];
        self.infoLabel.font = [UIFont systemFontOfSize:14.0];
        self.infoLabel.text = @"";
        self.infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        [self addSubview:self.infoLabel];
        
        self.edgeInsets = UIEdgeInsetsMake(6, 10, 9, 10);
    }
    
    return self;
}

- (void)dealloc
{
    self.accountDetails = nil;
    self.infoLabel = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds,self.edgeInsets);
    
    {
        CGRect infoRect = bounds;
        infoRect.size = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                                        constrainedToSize:bounds.size
                                            lineBreakMode:self.infoLabel.lineBreakMode];
        self.infoLabel.frame = infoRect;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat width = size.width - (self.edgeInsets.left + self.edgeInsets.right);
    
    CGSize textSize = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                                      constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                          lineBreakMode:self.infoLabel.lineBreakMode];
    
    textSize.height += (self.edgeInsets.top + self.edgeInsets.bottom);
    return textSize;
}

- (void)setAccountDetails:(NSDictionary *)accountDetails
{
    [_accountDetails release];
    _accountDetails = [accountDetails retain];
    NSInteger totalHolds = [[accountDetails objectForKey:@"total"] integerValue];
    NSInteger ready = [[accountDetails objectForKey:@"ready"] integerValue];

    NSMutableString *text = [NSMutableString stringWithFormat:kLibrariesHoldsStatusText, totalHolds, ((totalHolds == 1) ? @"request" : @"requests")];
    
    if (ready) {
        [text appendFormat:kLibrariesHoldsPickupText, ready, ((ready == 1) ? @"is" : @"are")];
    }
    self.infoLabel.text = text;
    
    [self setNeedsLayout];
}

@end
