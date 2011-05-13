//
//  HighlightTableViewCell.h
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HighlightLabel.h"

@interface HighlightTableViewCell : UITableViewCell {
    HighlightLabel *_highlightLabel;
}

@property (nonatomic,retain) HighlightLabel* highlightLabel;

@end
