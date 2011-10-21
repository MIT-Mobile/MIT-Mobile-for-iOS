#import "LibrariesHoldsSummaryView.h"

static NSString* kLibrariesHoldsStatusText = @"You have %@ hold requests.";
static NSString* kLibrariesHoldsPickupText = @"%@ are ready for pickup.";

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
        self.infoLabel.numberOfLines = 1;
        self.infoLabel.backgroundColor = [UIColor clearColor];
        self.infoLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        self.infoLabel.text = [NSString stringWithFormat:kLibrariesHoldsStatusText, @"0"];
        [self addSubview:self.infoLabel];
        
        self.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
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
    
    NSString *totalHolds = [accountDetails objectForKey:@"total"];
    if (totalHolds) {
        self.infoLabel.text = [NSString stringWithFormat:kLibrariesHoldsStatusText, totalHolds];
    } else {
        self.infoLabel.text = @"";
    }
    
    [self setNeedsLayout];
}

@end
