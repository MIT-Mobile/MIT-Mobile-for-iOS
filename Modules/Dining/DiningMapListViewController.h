//
//  DiningMapListViewController.h
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import <UIKit/UIKit.h>
#import "MITMapView.h"

@interface DiningMapListViewController : UIViewController

@property (nonatomic, readonly, strong) IBOutlet UITableView * listView;
@property (nonatomic, readonly, strong) IBOutlet UISegmentedControl * segmentControl;
@property (nonatomic, readonly, strong) IBOutlet MITMapView *mapView;
@property (nonatomic, readonly, assign) BOOL isAnimating;
@property (nonatomic, readonly, assign) BOOL isShowingMap;

@end
