//
//  PeopleSearchResultsViewController.h
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import <UIKit/UIKit.h>

#import "MITPeopleSearchHandler.h"
#import "MITPeopleSearchRootViewController.h"

@interface MITPeopleSearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) MITPeopleSearchHandler *searchHandler;

@property (nonatomic, strong) id<MITPeopleSearchViewControllerDelegate> delegate;

- (void) selectFirstResult;

@end
