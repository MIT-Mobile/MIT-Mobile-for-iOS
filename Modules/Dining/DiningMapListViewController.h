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

@property (nonatomic, readonly, strong) UITableView * listView;
@property (nonatomic, readonly, strong) UISegmentedControl * segmentControl;
@property (nonatomic, readonly, strong) MGSMapView *mapView;
@property (nonatomic, readonly, assign) BOOL isAnimating;
@property (nonatomic, readonly, assign) BOOL isShowingMap;

@end
