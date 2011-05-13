//
//  HighlightTableViewCell.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "HighlightTableViewCell.h"


@implementation HighlightTableViewCell
@synthesize highlightLabel = _highlightLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.autoresizesSubviews = YES;
        self.highlightLabel = [[[HighlightLabel alloc] init] autorelease];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)dealloc
{
    self.highlightLabel = nil;
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    frame.origin.x += 10;
    frame.size.width -= 20;
    
    self.highlightLabel.frame = frame;
    self.highlightLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight|
                              UIViewAutoresizingFlexibleWidth);
    [self.contentView addSubview:self.highlightLabel];
}

@end
