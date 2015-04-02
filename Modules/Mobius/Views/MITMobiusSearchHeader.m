#import "MITMobiusSearchHeader.h"
#import "UIKit+MITAdditions.h"

@interface MITMobiusSearchHeader ()
@property (weak, nonatomic) IBOutlet UILabel *shopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shopHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *shopStausLabel;
@end

@implementation MITMobiusSearchHeader

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
    return @"MITMobiusSearchHeader";
}

- (void)updateConstraints
{
    self.shopNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopNameLabel.frame);
    self.shopHoursLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopHoursLabel.frame);
    self.shopStausLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.shopStausLabel.frame);
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
    _shopHoursLabel.text = shopHours;
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setShopStaus:(NSString *)shopStaus
{
    if (![_shopHours isEqualToString:shopStaus]) {
        _shopStaus = [shopStaus copy];
        
        if ([shopStaus caseInsensitiveCompare:@"open"] == NSOrderedSame) {
            _shopStausLabel.textColor = [UIColor mit_openGreenColor];
        } else if ([shopStaus caseInsensitiveCompare:@"closed"] == NSOrderedSame) {
            _shopStausLabel.textColor = [UIColor mit_closedRedColor];
        }
        _shopStausLabel.text = shopStaus;
    }
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}
@end
