//
//  MITBatchScanningCell.m
//  MIT Mobile
//

#import "MITBatchScanningCell.h"

@interface MITBatchScanningCell()

@property (weak, nonatomic) IBOutlet UILabel *actionTitle;
@property (weak, nonatomic) IBOutlet UISwitch *actionToggleSwitch;
@property (weak, nonatomic) IBOutlet UILabel *actionDescription;

@end

@implementation MITBatchScanningCell

- (void)awakeFromNib {
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.actionDescription setFont:[UIFont systemFontOfSize:14]];
    [self.actionDescription setTextColor:[UIColor colorWithWhite:0.7 alpha:1.0]];
    
    [self.actionTitle setFont:[UIFont systemFontOfSize:17]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)toggleSwitchValueChanged:(UISwitch *)toggleSwitch
{
    [self.delegate toggleSwitchDidChangeValue:toggleSwitch inCell:self];
}

- (void)updateSettingDescriptionWithText:(NSString *)text
{
    [self.actionDescription setText:text];
}

- (void)setBatchScanningToggleSwitch:(BOOL)doBatchScanning
{
    [self.actionToggleSwitch setOn:doBatchScanning];
}

@end
