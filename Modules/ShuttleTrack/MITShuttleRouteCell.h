//
//  MITShuttleRouteCell.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/13/14.
//
//

#import <UIKit/UIKit.h>

@interface MITShuttleRouteCell : UITableViewCell

- (void)setRoute:(id)route;

+ (CGFloat)cellHeightForRoute:(id)route;

@end
