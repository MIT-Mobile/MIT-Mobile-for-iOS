//
//  MITScannerDetailTableViewCell.h
//  MIT Mobile
//

#import <UIKit/UIKit.h>

@interface MITScannerDetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *cellHeaderTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDescription;

- (void)removeLineSeparator;

@end
