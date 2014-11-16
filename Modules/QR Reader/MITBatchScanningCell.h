//
//  MITBatchScanningCell.h
//  MIT Mobile
//
//  Created by Yev Motov on 11/15/14.
//
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
