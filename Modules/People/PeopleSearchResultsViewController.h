//
//  PeopleSearchResultsViewController.h
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import <UIKit/UIKit.h>

#import "PeopleSearchHandler.h"
#import "PeopleSearchViewController_iPad.h"

@interface PeopleSearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) PeopleSearchHandler *searchHandler;

@property (nonatomic, strong) id<PeopleSearchViewControllerDelegate> delegate;

- (void) reload;

- (void) selectFirstResult;

@end
