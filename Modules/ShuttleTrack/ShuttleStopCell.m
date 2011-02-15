
#import "ShuttleStopCell.h"
#import "ShuttleStop.h"
#import "MITUIConstants.h"

@implementation ShuttleStopCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


-(void) setShuttleInfo:(ShuttleStop*)shuttleStop
{
	_shuttleNameLabel.text = shuttleStop.title;
	
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"h:mm a"];
	
	_shuttleTimeLabel.text = [formatter stringFromDate:shuttleStop.nextScheduledDate];

	if (shuttleStop.upcoming) 
	{
		_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next.png"] ;
		_shuttleTimeLabel.textColor = SEARCH_BAR_TINT_COLOR;
        _shuttleTimeLabel.font = [UIFont boldSystemFontOfSize:16.0];
		
	}
	else 
	{
		_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot.png"];
		_shuttleTimeLabel.textColor = [UIColor blackColor];
        _shuttleTimeLabel.font = [UIFont systemFontOfSize:16.0];
	}
}

@end
