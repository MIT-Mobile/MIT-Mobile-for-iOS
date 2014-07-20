//
//  MITPeopleRecentResultsViewController.h
//  MIT Mobile
//
//  Created by YevDev on 6/15/14.
//
//

#import <UIKit/UIKit.h>
#import "MITPeopleSearchRootViewController.h"
#import "MITPeopleSearchHandler.h"

@interface MITPeopleRecentResultsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITPeopleSearchHandler *searchHandler;
@property (nonatomic, weak) id<MITPeopleRecentsViewControllerDelegate> delegate;

- (void)reloadRecentResultsWithFilterString:(NSString *)filterString;

@end
