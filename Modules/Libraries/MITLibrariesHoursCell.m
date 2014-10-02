#import "MITLibrariesHoursCell.h"
#import "MITLibrariesTerm.h"
#import "UIKit+MITAdditions.h"

@interface MITLibrariesHoursCell ()

@property (weak, nonatomic) IBOutlet UILabel *termNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *termHoursLabel;

@end

@implementation MITLibrariesHoursCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.termNameLabel.textColor = [UIColor mit_tintColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width + 1, 0, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setContent:(id)content
{
    MITLibrariesTerm *term = (MITLibrariesTerm *)content;

    self.termNameLabel.text = [term termDescription];
    self.termHoursLabel.text = [term termHoursDescription];
    
    [self layoutIfNeeded];
}

+ (MITAutoSizingCell *)sizingCell
{
    static MITLibrariesHoursCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

+ (CGFloat)estimatedCellHeight
{
    return 67.0;
}

@end
