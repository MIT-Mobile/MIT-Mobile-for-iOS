//
//  MITShuttleRouteCell.m
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/13/14.
//
//

#import "MITShuttleRouteCell.h"

static const CGFloat kCellHeightNoAlert = 45.0;
static const CGFloat kCellHeightAlert = 62.0;

static const UILayoutPriority kAlertContainerViewHeightConstraintPriorityVisible = 1000;
static const UILayoutPriority kAlertContainerViewHeightConstraintPriorityHidden = 1;

@interface MITShuttleRouteCell()

@property (weak, nonatomic) IBOutlet UIImageView *statusIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *alertIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alertContainerViewHeightConstraint;

@end

@implementation MITShuttleRouteCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

- (void)setRoute:(id)route
{
    
}

+ (CGFloat)cellHeightForRoute:(id)route
{
    
}

@end
