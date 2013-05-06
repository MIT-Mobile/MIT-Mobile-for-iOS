//
//  DiningHallDetailViewController.h
//  MIT Mobile
//
//  Created by Austin Emmons on 4/2/13.
//
//

#import <UIKit/UIKit.h>
#import "DiningMenuFilterViewController.h"

@interface DiningHallMenuViewController : UITableViewController <DiningMenuFilterDelegate>

@property (nonatomic, strong) NSDictionary * hallData;

@end
