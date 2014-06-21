//
//  MITPeopleRecentResultsViewController.h
//  MIT Mobile
//
//  Created by YevDev on 6/15/14.
//
//

#import <UIKit/UIKit.h>
#import "MITPeopleSearchViewController_iPad.h"

@interface MITPeopleRecentResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) id<PeopleRecentsViewControllerDelegate> delegate;

@end
