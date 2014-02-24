#import "MITNewsLoadMoreTableViewCell.h"

@implementation MITNewsLoadMoreTableViewCell
@synthesize textLabel = _textLabelLoadMore;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (UILabel*)textLabel
{
    return _textLabelLoadMore;
}

@end
