
#import "MITDiningCustomSeparatorCell.h"

@interface MITDiningInfoScheduleCell : MITDiningCustomSeparatorCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *leftColumnLabel;
@property (nonatomic, strong) UILabel *rightColumnLabel;

@property (nonatomic) BOOL shouldIncludeTopPadding;
@property (nonatomic) NSInteger numberOfRowsInEachColumn;

+ (CGFloat)heightForCellWithNumberOfRowsInEachColumn:(NSInteger)numberOfRows withTopPadding:(BOOL)includeTopBuffer;

@end
