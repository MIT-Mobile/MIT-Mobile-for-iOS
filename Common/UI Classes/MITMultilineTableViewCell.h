//
//  MITMultilineTableViewCell.h
//  MIT Mobile
//
//  Created by Blake Skinner on 8/21/13.
//
//

#import <UIKit/UIKit.h>

@interface MITMultilineTableViewCell : UITableViewCell
@property (nonatomic,readonly,weak) UILabel *headlineLabel;
@property (nonatomic,readonly,weak) UILabel *bodyLabel;
@property UIEdgeInsets contentInset;

- (id)init;
@end
