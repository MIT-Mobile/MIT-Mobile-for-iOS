//
//  DiningMapListViewController.h
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import <UIKit/UIKit.h>
#import "MGSMapView.h"

@interface DiningMapListViewController : UIViewController

@property (nonatomic, readonly, strong) IBOutlet UITableView * listView;
@property (nonatomic, readonly, strong) IBOutlet UISegmentedControl * segmentControl;
@property (nonatomic, readonly, strong) IBOutlet MGSMapView *mapView;
@property (nonatomic, readonly, assign) BOOL isAnimating;
@property (nonatomic, readonly, assign) BOOL isShowingMap;

@end
