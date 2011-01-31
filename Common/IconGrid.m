#import "IconGrid.h"
#import "UIKit+MITAdditions.h"

GridPadding GridPaddingMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
    GridPadding padding = {top, left, bottom, right};
    return padding;
}

GridSpacing GridSpacingMake(CGFloat width, CGFloat height) {
    return (GridSpacing)CGSizeMake(width, height);
}

const GridPadding GridPaddingZero = {0, 0, 0, 0};
const GridSpacing GridSpacingZero = {0, 0};

@interface IconGrid (Private)

- (void)layoutRow:(NSArray *)rowIcons yOrigin:(CGFloat)yOrigin width:(CGFloat)rowWidth;

@end


@implementation IconGrid

@synthesize delegate, padding, spacing, maxColumns, alignment, icons;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        padding = GridPaddingZero;
        spacing = GridSpacingZero;
        maxColumns = 0;
        alignment = GridIconAlignmentLeft;
    }
    return self;
}

- (CGFloat)topPadding { return padding.top; }
- (CGFloat)rightPadding { return padding.right; }
- (CGFloat)bottomPadding { return padding.bottom; }
- (CGFloat)leftPadding { return padding.left; }

- (void)setTopPadding:(CGFloat)value { padding.top = value; }
- (void)setRightPadding:(CGFloat)value { padding.right = value; }
- (void)setBottomPadding:(CGFloat)value { padding.bottom = value; }
- (void)setLeftPadding:(CGFloat)value { padding.left = value; }

- (void)layoutSubviews {
    [self removeAllSubviews];
    [super layoutSubviews];

    CGFloat availableWidth = self.frame.size.width - self.leftPadding - self.rightPadding;
    if (availableWidth <= 0)
        return;
    
    CGFloat yOrigin = self.topPadding;
    
    NSMutableArray *iconsInCurrentRow = [NSMutableArray array];
    CGFloat currentRowWidth = 0;
    
    for (UIView *aView in self.icons) {
        
        CGFloat nextWidthNeeded = currentRowWidth + self.spacing.width + aView.frame.size.width;
        CGFloat iconCount = iconsInCurrentRow.count;
        // if we have a full row or are at the end, layout icons and flush the icons buffer
        if ((iconCount && nextWidthNeeded > availableWidth) || (self.maxColumns && iconCount >= self.maxColumns))
        {
            [self layoutRow:iconsInCurrentRow yOrigin:yOrigin width:currentRowWidth];
            
            CGFloat maxHeightInRow = 0;
            for (UIView *rowView in iconsInCurrentRow) {
                if (rowView.frame.size.height > maxHeightInRow)
                    maxHeightInRow = rowView.frame.size.height;
            }
            yOrigin += maxHeightInRow + spacing.height;
            
            [iconsInCurrentRow removeAllObjects];
            currentRowWidth = 0;
        }
        
        // add our view to the queue, which may or may not be emtpy(ied)
        [iconsInCurrentRow addObject:aView];
        currentRowWidth += aView.frame.size.width;
        if ([iconsInCurrentRow count] > 1) {
            currentRowWidth += spacing.width;        
        }
    }
    // finish the loop
    [self layoutRow:iconsInCurrentRow yOrigin:yOrigin width:currentRowWidth];
    
    // resize our frame if it is too short to fit all icons.
    CGFloat maxHeight = 0;
    for (UIView *anIcon in iconsInCurrentRow) {
        if (maxHeight < anIcon.frame.size.height)
            maxHeight = anIcon.frame.size.height;
    }
    if (self.frame.size.height < maxHeight + yOrigin + self.bottomPadding) {
        CGRect frame = self.frame;
        frame.size.height = maxHeight + yOrigin + self.bottomPadding;
        self.frame = frame;

		if ([delegate respondsToSelector:@selector(iconGridFrameDidChange:)]) {
			[delegate iconGridFrameDidChange:self];
		}
    }
}

- (void)layoutRow:(NSArray *)rowIcons yOrigin:(CGFloat)yOrigin width:(CGFloat)rowWidth {
    CGFloat xOrigin;
    switch (alignment) {
        case GridIconAlignmentRight:
            xOrigin = self.frame.size.width - self.rightPadding - rowWidth;
            break;
        case GridIconAlignmentCenter:
            xOrigin = floor(self.frame.size.width - rowWidth / 2);
            break;
        case GridIconAlignmentLeft:
        default:
            xOrigin = self.leftPadding;
            break;
    }
    
    CGRect currentFrame;
    for (UIView *rowView in rowIcons) {
        currentFrame = rowView.frame;
        currentFrame.origin.x = xOrigin;
        currentFrame.origin.y = yOrigin;
        rowView.frame = currentFrame;
        [self addSubview:rowView];
        
        xOrigin += currentFrame.size.width + self.spacing.width;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
