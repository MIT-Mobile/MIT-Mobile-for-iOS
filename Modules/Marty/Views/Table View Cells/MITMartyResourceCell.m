#import "MITMartyResourceCell.h"
#import "MITMartyResource.h"
#import "UIKit+MITAdditions.h"

const CGFloat kResourceCellEstimatedHeight = 50.0;

@interface MITMartyResourceCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation MITMartyResourceCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.frame.size.width;
    self.subtitleLabel.preferredMaxLayoutWidth = self.subtitleLabel.frame.size.width;
    self.statusLabel.preferredMaxLayoutWidth = self.statusLabel.frame.size.width;
    
}

#pragma mark - Resource

- (void)setResource:(MITMartyResource *)resource
{
    self.titleLabel.text = resource.title;
    self.subtitleLabel.text = resource.subtitle;
    self.statusLabel.text = resource.status;
}

- (void)setResource:(MITMartyResource *)resource order:(NSInteger)order
{
    self.titleLabel.text = [NSString stringWithFormat:@"%ld. %@", (long)order, resource.title];
    self.subtitleLabel.text = resource.subtitle;
    self.statusLabel.text = resource.status;
    [self setStatusLabelColor:self.statusLabel];
}

- (void)setStatusLabelColor:(UILabel *)statusLabel
{
    if ([statusLabel.text caseInsensitiveCompare:@"online"] == NSOrderedSame) {
        statusLabel.textColor = [UIColor mit_openGreenColor];
    } else if ([statusLabel.text caseInsensitiveCompare:@"offline"] == NSOrderedSame) {
        statusLabel.textColor = [UIColor mit_closedRedColor];
    }
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForResource:(MITMartyResource *)resource
                    order:(NSInteger)order
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    [[MITMartyResourceCell sizingCell] setResource:resource order:order];
    return [MITMartyResourceCell heightForCell:[MITMartyResourceCell sizingCell] TableWidth:width accessoryType:accessoryType];
}

+ (CGFloat)heightForResource:(MITMartyResource *)resource
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    [[MITMartyResourceCell sizingCell] setResource:resource];
    return [MITMartyResourceCell heightForCell:[MITMartyResourceCell sizingCell] TableWidth:width accessoryType:accessoryType];
}

+ (CGFloat)heightForCell:(MITMartyResourceCell *)cell TableWidth:(CGFloat)width accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    cell.accessoryType = accessoryType;
    
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kResourceCellEstimatedHeight, height);
}

+ (MITMartyResourceCell *)sizingCell
{
    static MITMartyResourceCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITMartyResourceCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
