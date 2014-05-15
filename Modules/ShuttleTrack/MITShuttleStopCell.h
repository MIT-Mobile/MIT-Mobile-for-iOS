//
//  MITShuttleStopCell.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/14/14.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    MITShuttleStopCellTypeRouteList,
    MITShuttleStopCellTypeRouteDetail
} MITShuttleStopCellType;

@interface MITShuttleStopCell : UITableViewCell

- (void)setCellType:(MITShuttleStopCellType)cellType;
- (void)setStop:(id)stop;

@end
