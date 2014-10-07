#import "MITLibrariesSingleTitleLabelCell.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesSingleTitleLabelCell ()

@property (nonatomic, weak) IBOutlet UILabel *customTextLabel;

@end

@implementation MITLibrariesSingleTitleLabelCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setContent:(NSString *)textForLabel
{
    self.customTextLabel.text = textForLabel;
}

@end
