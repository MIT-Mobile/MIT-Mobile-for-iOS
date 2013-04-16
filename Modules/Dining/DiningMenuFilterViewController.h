//
//  DiningMenuFilterViewController.h
//  MIT Mobile
//
//  Created by Austin Emmons on 4/11/13.
//
//

#import <UIKit/UIKit.h>

@protocol DiningMenuFilterDelegate <NSObject>

- (void) applyFilters:(NSArray *) filters;

@end

@interface DiningMenuFilterViewController : UITableViewController

@property (nonatomic) id<DiningMenuFilterDelegate> delegate;

- (void) setFilters:(NSArray *)filters;

@end
