#import <UIKit/UIKit.h>
#import "HighlightLabel.h"

@interface HighlightTableViewCell : UITableViewCell {
    HighlightLabel *_highlightLabel;
}

@property (nonatomic,retain) HighlightLabel* highlightLabel;

@end
