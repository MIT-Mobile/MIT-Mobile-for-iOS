#import "MITDiningDietaryFlagListCell.h"
#import "UIImage+PDF.h"
#import "MITDiningMenuItem.h"

static CGFloat const kMITDiningDietaryFlagListCellRightPadding = 10;

@interface MITDiningDietaryFlagListCell ()

@property (nonatomic, strong) IBOutlet UIImageView *flagImageView;
@property (nonatomic, strong) IBOutlet UILabel *flagTitleLabel;

@end

@implementation MITDiningDietaryFlagListCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFlag:(NSString *)flag
{
    UIImage *flagImage = [UIImage imageWithPDFNamed:[MITDiningMenuItem pdfNameForDietaryFlag:flag] fitSize:CGSizeMake(24, 24)];
    
    self.flagTitleLabel.text = [MITDiningMenuItem displayNameForDietaryFlag:flag];
    self.flagImageView.image = flagImage;
}

- (CGFloat)targetWidth
{
    return self.flagTitleLabel.frame.origin.x + ceil([self.flagTitleLabel.text sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}].width) + kMITDiningDietaryFlagListCellRightPadding;
}

@end
