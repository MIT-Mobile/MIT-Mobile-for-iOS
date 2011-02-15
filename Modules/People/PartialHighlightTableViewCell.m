#import "PartialHighlightTableViewCell.h"
#import "MITUIConstants.h"

#define REPLACED_TEXTLABEL_TAG 999

@implementation PartialHighlightTableViewCell

- (void)prepareForReuse {
	// clean up extra views we added before
	UIView *view = nil;
	while ((view = [self viewWithTag:REPLACED_TEXTLABEL_TAG])) {
		[view removeFromSuperview];
	}
	
	[super prepareForReuse];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self applyStandardFonts];
	
	UIView *replaceTextLabel = [self viewWithTag:REPLACED_TEXTLABEL_TAG];
	
	if (replaceTextLabel == nil) {
		
		CGRect frame = CGRectMake(self.textLabel.frame.origin.x, 
								  4.0, 
								  self.textLabel.frame.size.width, 
								  self.textLabel.frame.size.height);
		
		replaceTextLabel = [[UIView alloc] initWithFrame:frame];
		replaceTextLabel.tag = REPLACED_TEXTLABEL_TAG;
		replaceTextLabel.backgroundColor = [UIColor clearColor];
		UIFont *regularFont = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE];
		UIFont *boldFont = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
		
		CGSize labelSize;
		CGFloat x = 0.0;
		
		NSArray *tails = [self.textLabel.text componentsSeparatedByString:@"["];
		
		for (NSString *tail in tails) {
			
			// label used for bold substrings
			UILabel *left = [[UILabel alloc] initWithFrame:CGRectZero];
			left.backgroundColor = [UIColor clearColor];
			left.font = boldFont;
			left.textColor = CELL_STANDARD_FONT_COLOR;
			left.highlightedTextColor = [UIColor whiteColor];
			
			// label used for regular font substrings
			UILabel *right = [[UILabel alloc] initWithFrame:CGRectZero];
			right.backgroundColor = [UIColor clearColor];
			right.font = regularFont;
			right.textColor = CELL_STANDARD_FONT_COLOR;
			right.highlightedTextColor = [UIColor whiteColor];
			
			NSArray *parts = [tail componentsSeparatedByString:@"]"];
			if ([parts count] == 1) {
				labelSize = [[parts objectAtIndex:0] sizeWithFont:regularFont];
				right.frame = CGRectMake(x, frame.origin.y, labelSize.width, labelSize.height);
				right.text = [parts objectAtIndex:0];
				[replaceTextLabel addSubview:right];
				x += labelSize.width;
				
			} else {
				labelSize = [[parts objectAtIndex:0] sizeWithFont:boldFont];
				left.frame = CGRectMake(x, frame.origin.y, labelSize.width, labelSize.height);
				left.text = [parts objectAtIndex:0];
				[replaceTextLabel addSubview:left];
				x += labelSize.width;
				
				labelSize = [[parts objectAtIndex:1] sizeWithFont:regularFont];
				right.frame = CGRectMake(x, frame.origin.y, labelSize.width, labelSize.height);
				right.text = [parts objectAtIndex:1];
				[replaceTextLabel addSubview:right];
				x += labelSize.width;
				
			}
			
			// truncate characters past the initial frame border, if any
			if (x >= frame.size.width) {
				[right removeFromSuperview];
				x -= right.frame.size.width;
				
				// truncate last non-bold label first
				while (right.text.length > 0) {
					right.text = [right.text substringToIndex:right.text.length-1];
					labelSize = [[right.text stringByAppendingString:@"..."] sizeWithFont:regularFont];
					if (x + labelSize.width < frame.size.width) {
						break;
					}
				}
				
				right.text = [right.text stringByAppendingString:@"..."];
				right.frame = CGRectMake(x, right.frame.origin.y, labelSize.width, right.frame.size.height);
				
				// truncate last bold label, this should be rare
				if (x + right.frame.size.width >= frame.size.width) {
					[left removeFromSuperview];
					x -= left.frame.size.width;
					while (left.text.length > 0) {
						left.text = [left.text substringToIndex:left.text.length-1];
						labelSize = [left.text sizeWithFont:boldFont];
						if (x + labelSize.width + right.frame.size.width < frame.size.width) {
							break;
						}
					}
					
					// need to move right.frame again since we moved x
					left.frame = CGRectMake(x, left.frame.origin.y, labelSize.width, left.frame.size.height);
					right.frame = CGRectMake(x + left.frame.size.width, right.frame.origin.y, right.frame.size.width, right.frame.size.height);
					[replaceTextLabel addSubview:left];
				}
				
				[replaceTextLabel addSubview:right];
				
				[left release];
				[right release];
				break;
			}
			
			[left release];
			[right release];
		}
		
		[self addSubview:replaceTextLabel];
		[replaceTextLabel release];
		
	} else {
		for (UIView *view in [replaceTextLabel subviews]) {
			UILabel *label = (UILabel *)view;
			label.highlighted = (self.selected || self.highlighted);
		}
	}

	[self.textLabel removeFromSuperview];
}

- (void)dealloc {
    [super dealloc];
}


@end
