//
//  FacilitiesTypeViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 5/5/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FacilitiesTypeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSDictionary *_userData;
    UITableView *_tableView;
}

@property (nonatomic,copy) NSDictionary *userData;
@property (nonatomic,retain) UITableView* tableView;

@end
