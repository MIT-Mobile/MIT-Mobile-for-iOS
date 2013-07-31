#import "LibrariesHoldsSummaryView.h"
#import "UIKit+MITAdditions.h"

static NSString* kLibrariesHoldsStatusText = @"You have %ld hold %@.";
static NSString* kLibrariesHoldsPickupText = @"\n%ld %@ ready for pickup.";

@interface LibrariesHoldsSummaryView ()
@property (nonatomic,weak) UILabel *infoLabel;
@end

@implementation LibrariesHoldsSummaryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *infoLabel = [[UILabel alloc] init];
        infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        infoLabel.numberOfLines = 2;
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.font = [UIFont systemFontOfSize:14.0];
        infoLabel.text = @"";
        infoLabel.textColor = [UIColor colorWithHexString:@"#404649"];
        [self addSubview:infoLabel];
        self.infoLabel = infoLabel;
        
        self.edgeInsets = UIEdgeInsetsMake(6, 10, 9, 10);
    }
    
    return self;
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
    _accountDetails = [accountDetails copy];
    NSInteger totalHolds = [accountDetails[@"total"] integerValue];
    NSInteger ready = [accountDetails[@"ready"] integerValue];

    NSMutableString *text = [NSMutableString stringWithFormat:kLibrariesHoldsStatusText, totalHolds, ((totalHolds == 1) ? @"request" : @"requests")];
    
    if (ready) {
        [text appendFormat:kLibrariesHoldsPickupText, ready, ((ready == 1) ? @"is" : @"are")];
    }
    self.infoLabel.text = text;
    
    [self setNeedsLayout];
}

@end
