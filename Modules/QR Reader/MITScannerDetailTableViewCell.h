//
//  MITScannerDetailTableViewCell.h
//  MIT Mobile
//
//  Created by Yev Motov on 11/22/14.
//
//

#import <UIKit/UIKit.h>

@interface MITScannerDetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *cellHeaderTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDescription;

- (void)removeLineSeparator;

@end
