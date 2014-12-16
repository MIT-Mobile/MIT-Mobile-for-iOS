//
//  MITScannerDetailTableViewCell.m
//  MIT Mobile
//

#import "MITScannerDetailTableViewCell.h"
#import "UIKit+MITAdditions.h"

@implementation MITScannerDetailTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    [self.cellHeaderTitle setTextColor:[UIColor mit_tintColor]];
    [self.cellHeaderTitle setFont:[UIFont systemFontOfSize:14]];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) removeLineSeparator
{
    self.separatorInset = UIEdgeInsetsMake(0, 1000.0, 0, 0);
}

@end
