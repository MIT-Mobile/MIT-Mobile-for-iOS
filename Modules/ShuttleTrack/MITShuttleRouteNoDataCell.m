//
//  MITShuttleRouteNoDataCell.m
//  MIT Mobile
//
//  Created by Ross LeBeau on 5/29/14.
//
//

#import "MITShuttleRouteNoDataCell.h"
#import "MITShuttleRoute.h"

NSString * const kMITShuttleRouteNoDataCellNibName = @"MITShuttleRouteNoDataCell";

@interface MITShuttleRouteNoDataCell ()

@property (nonatomic, weak) IBOutlet UIImageView *leftImageView;
@property (nonatomic, weak) IBOutlet UILabel *mainLabel;

@end

@implementation MITShuttleRouteNoDataCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public Methods

- (void)setNoPredictions:(MITShuttleRoute *)route
{
    self.leftImageView.image = nil;
    self.mainLabel.text = route.routeDescription;
}

- (void)setNotInService:(MITShuttleRoute *)route
{
    self.leftImageView.image = [UIImage imageNamed:@"shuttle/shuttle-off"];
    self.mainLabel.text = route.routeDescription;
}

@end
