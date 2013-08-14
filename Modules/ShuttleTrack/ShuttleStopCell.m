
#import "ShuttleStopCell.h"
#import "ShuttleStop.h"
#import "MITUIConstants.h"

@interface ShuttleStopCell ()

@property(nonatomic, strong) IBOutlet UIImageView* shuttleStopImageView;
@property(nonatomic, strong) IBOutlet UILabel* shuttleNameLabel;
@property(nonatomic, strong) IBOutlet UILabel* shuttleTimeLabel;

@end

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

-(void) setShuttleInfo:(ShuttleStop*)shuttleStop
{
	self.shuttleNameLabel.text = shuttleStop.title;
	
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"h:mm a"];
	
	self.shuttleTimeLabel.text = [formatter stringFromDate:shuttleStop.nextScheduledDate];

	if (shuttleStop.upcoming) 
	{
		self.shuttleStopImageView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next.png"] ;
		self.shuttleTimeLabel.textColor = SEARCH_BAR_TINT_COLOR;
        self.shuttleTimeLabel.font = [UIFont boldSystemFontOfSize:16.0];
		
	}
	else 
	{
		self.shuttleStopImageView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot.png"];
		self.shuttleTimeLabel.textColor = [UIColor blackColor];
        self.shuttleTimeLabel.font = [UIFont systemFontOfSize:16.0];
	}
}

@end
