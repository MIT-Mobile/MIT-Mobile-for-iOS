#import "MITLibrariesSingleSubtitleLabelCell.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesSingleSubtitleLabelCell ()

@property (nonatomic, weak) IBOutlet UILabel *customTextLabel;

@end

@implementation MITLibrariesSingleSubtitleLabelCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.customTextLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
}

- (void)setContent:(NSString *)textForLabel
{
    self.customTextLabel.text = textForLabel;
}

@end
