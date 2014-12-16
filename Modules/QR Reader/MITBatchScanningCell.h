//
//  MITBatchScanningCell.h
//  MIT Mobile
//

#import <UIKit/UIKit.h>

@class MITBatchScanningCell;

@protocol MITBatchScanningCellDelegate <NSObject>

- (void)toggleSwitchDidChangeValue:(UISwitch *)toggleSwitch inCell:(MITBatchScanningCell *)cell;

@end

@interface MITBatchScanningCell : UITableViewCell

@property (nonatomic, weak) id<MITBatchScanningCellDelegate> delegate;

- (void)setBatchScanningToggleSwitch:(BOOL)doBatchScanning;
- (void)updateSettingDescriptionWithText:(NSString *)text;

@end
