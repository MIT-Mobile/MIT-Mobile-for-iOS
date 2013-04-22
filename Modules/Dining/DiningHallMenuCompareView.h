//
//  DiningHallMenuCompareView.h
//  MIT Mobile
//
//  Created by Austin Emmons on 4/8/13.
//
//

#import <UIKit/UIKit.h>

@interface DiningHallMenuCompareView : UIView

@property (nonatomic, readonly, strong) UILabel * headerView;
@property (nonatomic, strong) NSDate *date;

- (void) resetScrollOffset;

@end
