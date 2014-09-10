#import "MITDiningInfoScheduleCell.h"

@interface MITDiningRetailInfoScheduleCell : MITDiningInfoScheduleCell

@property (strong, nonatomic) NSArray *scheduleInfo;

+ (CGFloat)heightForCellWithScheduleInfo:(NSArray *)scheduleInfo;

@end
