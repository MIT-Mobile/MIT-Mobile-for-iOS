#import "MITToursTourStopCell.h"
#import "MITToursStopCellModel.h"
#import "UIImageView+WebCache.h"

@interface MITToursTourStopCell ()

@property (weak, nonatomic) IBOutlet UIImageView *stopImageView;

@property (weak, nonatomic) IBOutlet UILabel *stopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@end

@implementation MITToursTourStopCell

- (void)awakeFromNib
{
    self.separatorInset = UIEdgeInsetsMake(0, 91, 0, 0);
}

- (void)setContent:(id)content
{
    MITToursStopCellModel *stopCellModel = (MITToursStopCellModel *)content;
    self.stopNameLabel.text = stopCellModel.titleText;
    self.distanceLabel.text = stopCellModel.distanceText;
    
    [self.stopImageView sd_setImageWithURL:[NSURL URLWithString:stopCellModel.stop.thumbnailURL]];
}

+ (CGFloat)estimatedCellHeight
{
    return 104.0;
}

@end
