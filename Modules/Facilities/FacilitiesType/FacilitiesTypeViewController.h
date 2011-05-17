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
}

@property (nonatomic,copy) NSDictionary *userData;

@end
