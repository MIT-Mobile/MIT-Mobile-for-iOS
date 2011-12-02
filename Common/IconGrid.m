#import "IconGrid.h"
#import "UIKit+MITAdditions.h"

@implementation IconGrid

@synthesize delegate, icons, horizontalMargin, verticalMargin, horizontalPadding, verticalPadding, minColumns, maxColumns;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.horizontalMargin = 0.0;
        self.verticalMargin = 0.0;
        self.horizontalPadding = 0.0;
        self.verticalPadding = 0.0;
        self.delegate = nil;
        self.icons = nil;
    }
    return self;
}

- (void)setHorizontalMargin:(CGFloat)hMargin vertical:(CGFloat)vMargin {
    self.horizontalMargin = hMargin;
    self.verticalMargin = vMargin;
}

- (void)setHorizontalPadding:(CGFloat)hPadding vertical:(CGFloat)vPadding {
    self.horizontalPadding = hPadding;
    self.verticalPadding = vPadding;
}

- (void)setMinimumColumns:(NSInteger)min maximum:(NSInteger)max {
    self.minColumns = min;
    self.maxColumns = max;
}


- (void)layoutSubviews {
    [self removeAllSubviews];
    [super layoutSubviews];

    // calculate the maximum number of columns possible
    NSInteger iconCount = [self.icons count];
    
    UIView *anIcon = [self.icons lastObject];
    CGSize iconSize = anIcon.frame.size;
    CGFloat maxContainerWidth = self.frame.size.width - (self.horizontalMargin * 2.0);
    CGFloat rowHeight = iconSize.height + self.verticalPadding;
    
    // only fit as many as we can
    // max icons if done without padding (slightly overcompensates the padding)
    NSInteger maxPossibleColumns = (NSInteger)floor(maxContainerWidth / (iconSize.width + self.horizontalPadding));
    self.maxColumns = (maxPossibleColumns < self.maxColumns) ? maxPossibleColumns : self.maxColumns;
    
    // calculate the minimum number of columns we can get away with
    // while still fitting everything on screen
    NSInteger columns = self.minColumns;
    for (; columns <= self.maxColumns; columns++) {
        NSInteger rows = (NSInteger)ceil(iconCount / (float)columns);
        // stop looking once we find a number of rows which fit in one view
        if (self.frame.size.height >= rows * rowHeight) {
            break;
        }
        // or just spill off the end and end up with maxAllowedColumns
    }
    
    // calculate the padding needed on each side to keep these columns 
    // evenly spaced and centered horizontally
    CGFloat maxIconPaddingPerSide = ((maxContainerWidth / columns) - iconSize.width) / 2.0;
    
    // lay out icons
    CGFloat xOrigin = self.horizontalMargin + maxIconPaddingPerSide;
    CGFloat yOrigin = self.verticalMargin;
    
    NSInteger i = 0;
    
    for (UIView *aView in self.icons) {
        aView.frame = CGRectMake(floor(xOrigin), floor(yOrigin), aView.frame.size.width, aView.frame.size.height);
        [self addSubview:aView];
        
        // add right padding
        xOrigin += iconSize.width + (maxIconPaddingPerSide * 2.0);
        
        i++;
        // wrap to the next row as needed
        if (i >= columns) {
            i = 0;
            xOrigin = self.horizontalMargin + maxIconPaddingPerSide;
            yOrigin += rowHeight;
        }
    }
    
    // resize our frame if it is too short to fit all icons.
    CGFloat maxHeight = 0;
    for (UIView *anIcon in self.icons) {
        if (maxHeight < anIcon.frame.size.height)
            maxHeight = anIcon.frame.size.height;
    }
    
    if (self.frame.size.height < maxHeight + yOrigin + self.verticalMargin) {
        CGRect frame = self.frame;
        frame.size.height = maxHeight + yOrigin + self.verticalMargin;
        self.frame = frame;

		if ([delegate respondsToSelector:@selector(iconGridFrameDidChange:)]) {
			[delegate iconGridFrameDidChange:self];
		}
    }
}

- (void)dealloc {
    [super dealloc];
    // TODO: check if this needs to release self.icons
}


@end
