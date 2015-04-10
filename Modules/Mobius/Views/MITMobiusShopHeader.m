#import "MITMobiusShopHeader.h"
#import "UIKit+MITAdditions.h"

@interface MITMobiusShopHeader ()
@property (weak, nonatomic) IBOutlet UILabel *shopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shopHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *shopStatusLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSeparatorHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSeparatorVerticalSpaceConstraint;
@end

@implementation MITMobiusShopHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

+ (UINib *)searchHeaderNib
{
    return [UINib nibWithNibName:self.searchHeaderNibName bundle:nil];
}

+ (NSString *)searchHeaderNibName
{
    return @"MITMobiusShopHeader";
}

- (void)updateConstraints
{
    self.shopNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopNameLabel.frame);
    self.shopHoursLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopHoursLabel.frame);
    self.shopStatusLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopStatusLabel.frame);

    CGFloat onePixel = 1 / [[UIScreen mainScreen] scale];
    self.topSeparatorHeightConstraint.constant = onePixel;
    self.bottomSeparatorHeightConstraint.constant = onePixel;
    self.topSeparatorVerticalSpaceConstraint.constant = -1.0 * onePixel;

    [super updateConstraints];
}

- (void)setShopName:(NSString *)shopName
{
    if (![_shopName isEqualToString:shopName]) {
        _shopName = [shopName copy];
        _shopNameLabel.text = shopName;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setShopHours:(NSString *)shopHours
{
    if (![_shopHours isEqualToString:shopHours]) {
        _shopHours = [shopHours copy];
        _shopHoursLabel.text = shopHours;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setStatus:(MITMobiusShopStatus)status
{
    switch (status) {
        case MITMobiusShopStatusClosed: {
            self.shopStatusLabel.text = @"Closed";
            self.shopStatusLabel.textColor = [UIColor mit_closedRedColor];
        } break;
            
        case MITMobiusShopStatusOpen: {
            self.shopStatusLabel.text = @"Open";
            self.shopStatusLabel.textColor = [UIColor mit_openGreenColor];
        } break;
            
        case MITMobiusShopStatusUnknown: {
            self.shopStatusLabel.text = @"";
        } break;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];

}

@end
