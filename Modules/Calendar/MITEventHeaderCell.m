#import "MITEventHeaderCell.h"

@interface MITEventHeaderCell ()

@property (nonatomic, weak) IBOutlet UILabel *eventTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *partOfSeriesLabel;

@end

@implementation MITEventHeaderCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.eventTitleLabel.preferredMaxLayoutWidth = self.eventTitleLabel.bounds.size.width;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public Methods

- (void)setEventTitle:(NSString *)eventTitle isPartOfSeries:(BOOL)isPartOfSeries
{
    self.eventTitleLabel.text = eventTitle;
    self.partOfSeriesLabel.hidden = !isPartOfSeries;
}

@end
