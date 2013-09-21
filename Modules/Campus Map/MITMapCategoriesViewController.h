//
//  MITMapCategoriesViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 2013/09/20.
//
//

#import <UIKit/UIKit.h>

@interface MITMapCategoriesViewController : UITableViewController
@property (nonatomic,copy) NSDictionary *categories;

- (id)init;
- (id)initWithCategories:(NSDictionary*)categories;
@end
