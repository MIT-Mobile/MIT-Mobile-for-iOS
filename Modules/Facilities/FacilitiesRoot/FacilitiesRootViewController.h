//
//  FacilitiesRootViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/20/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FacilitiesRootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITextView *_textView;
    UITableView *_tableView;
}

@property (nonatomic,readonly,retain) IBOutlet UITextView *textView;
@property (nonatomic,readonly,retain) IBOutlet UITableView* tableView;

@end
