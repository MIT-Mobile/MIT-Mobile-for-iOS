#import "LibrariesHoldsSummaryView.h"

static NSString* kLibrariesHoldsStatusText = @"You have %@ hold requests.";
static NSString* kLibrariesHoldsPickupText = @"%@ are ready for pickup.";

@interface LibrariesHoldsSummaryView ()
@property (nonatomic,retain) UILabel *infoLabel;
@end

@implementation LibrariesHoldsSummaryView
@synthesize accountDetails = _accountDetails,
infoLabel = _infoLabel;

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
    }
    
    return self;
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
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
    CGSize finalSize = CGSizeZero;
    finalSize.width = size.width;
    
    CGSize textSize = [self.infoLabel.text sizeWithFont:self.infoLabel.font
                               constrainedToSize:size
                                   lineBreakMode:self.infoLabel.lineBreakMode];
    finalSize.height = textSize.height;
    return finalSize;
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
