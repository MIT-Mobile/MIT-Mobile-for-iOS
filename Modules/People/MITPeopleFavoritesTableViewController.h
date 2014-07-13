//
//  MITPeopleFavoritesTableViewController.h
//  MIT Mobile
//
//  Created by Yev Motov on 6/20/14.
//
//

#import <UIKit/UIKit.h>
#import "MITPeopleSearchRootViewController.h"

@interface MITPeopleFavoritesTableViewController : UITableViewController

@property (nonatomic, weak) id<MITPeopleFavoritesViewControllerDelegate> delegate;

@end
