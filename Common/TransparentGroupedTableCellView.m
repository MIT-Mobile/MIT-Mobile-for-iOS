// Based on sample code from http://stackoverflow.com/questions/400965/how-to-customize-the-background-border-colors-of-a-grouped-table-view 

// Usage: set as the backgroundView of a grouped tableview cell which you want to be transparent

#import "TransparentGroupedTableCellView.h"

static void addRoundedRectToPath(CGContextRef context, CGRect rect,
                                 float ovalWidth,float ovalHeight);

@implementation TransparentGroupedTableCellView
@synthesize borderColor, fillColor, position;

- (BOOL) isOpaque {
    return NO;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#define CORNER_RADIUS 10.0f
#define LINE_WIDTH 0.5f

-(void)drawRect:(CGRect)rect 
{
    // Drawing code
    
    rect.origin.y += 1.0f;
    rect.size.height -= 1.0f;
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, [fillColor CGColor]);
    CGContextSetStrokeColorWithColor(c, [borderColor CGColor]);
    CGContextSetLineWidth(c, LINE_WIDTH);
    
    if (position == TransparentGroupedTableCellViewPositionTop) {
        
        CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
        CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
        minx = minx + 1;
        miny = miny - 1;
        
        maxx = maxx - 1;
        maxy = maxy ;

        CGContextMoveToPoint(c, minx, maxy);
        CGContextAddArcToPoint(c, minx, miny, midx, miny, CORNER_RADIUS);
        CGContextAddArcToPoint(c, maxx, miny, maxx, maxy, CORNER_RADIUS);
        CGContextAddLineToPoint(c, maxx, maxy);
        
        // Close the path
        CGContextClosePath(c);
        // Fill & stroke the path
        CGContextDrawPath(c, kCGPathFillStroke);                
        return;
    } else if (position == TransparentGroupedTableCellViewPositionBottom) {
        
        CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
        CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
        minx = minx + 1;
        miny = miny ;
        
        maxx = maxx - 1;
        maxy = maxy - 1;
        
        CGContextMoveToPoint(c, minx, miny);
        CGContextAddArcToPoint(c, minx, maxy, midx, maxy, CORNER_RADIUS);
        CGContextAddArcToPoint(c, maxx, maxy, maxx, miny, CORNER_RADIUS);
        CGContextAddLineToPoint(c, maxx, miny);
        // Close the path
        CGContextClosePath(c);
        // Fill & stroke the path
        CGContextDrawPath(c, kCGPathFillStroke);        
        return;
    } else if (position == TransparentGroupedTableCellViewPositionMiddle) {
        CGFloat minx = CGRectGetMinX(rect) , maxx = CGRectGetMaxX(rect) ;
        CGFloat miny = CGRectGetMinY(rect) , maxy = CGRectGetMaxY(rect) ;
        minx = minx + 1;
        miny = miny ;
        
        maxx = maxx - 1;
        maxy = maxy ;
        
        CGContextMoveToPoint(c, minx, miny);
        CGContextAddLineToPoint(c, maxx, miny);
        CGContextAddLineToPoint(c, maxx, maxy);
        CGContextAddLineToPoint(c, minx, maxy);
        
        CGContextClosePath(c);
        // Fill & stroke the path
        CGContextDrawPath(c, kCGPathFillStroke);        
        return;
    } else if (position == TransparentGroupedTableCellViewPositionSingle) {
            CGFloat minx = CGRectGetMinX(rect) , midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) ;
            CGFloat miny = CGRectGetMinY(rect) , midy = CGRectGetMidY(rect) , maxy = CGRectGetMaxY(rect) ;
            minx = minx + 1;
            miny = miny + 1;
            
            maxx = maxx - 1;
            maxy = maxy - 1;
            
            CGContextMoveToPoint(c, minx, midy);
            CGContextAddArcToPoint(c, minx, miny, midx, miny, CORNER_RADIUS);
            CGContextAddArcToPoint(c, maxx, miny, maxx, midy, CORNER_RADIUS);
            CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, CORNER_RADIUS);
            CGContextAddArcToPoint(c, minx, maxy, minx, midy, CORNER_RADIUS);
            
            // Close the path
            CGContextClosePath(c);
            // Fill & stroke the path
            CGContextDrawPath(c, kCGPathFillStroke);                
            return;         
    }
}


- (void)dealloc {
    [borderColor release];
    [fillColor release];
    [super dealloc];
}

- (void)setPosition:(TransparentGroupedTableCellViewPosition)newPosition {
    if (position != newPosition) {
        position = newPosition;
        [self setNeedsDisplay]; // required to make sure reused cells actually have their backgrounds redrawn
    }
}

- (void)updatePositionForIndex:(NSInteger)index total:(NSInteger)total {
    if (total == 1) {
        self.position = TransparentGroupedTableCellViewPositionSingle;
    } else if (index == 0) {
        self.position = TransparentGroupedTableCellViewPositionTop;
    } else if (index < total - 1) {
        self.position = TransparentGroupedTableCellViewPositionMiddle;
    } else {
        self.position = TransparentGroupedTableCellViewPositionBottom;
    }
}


@end

static void addRoundedRectToPath(CGContextRef context, CGRect rect,
                                 float ovalWidth,float ovalHeight)

{
    float fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0) {// 1
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);// 2
    
    CGContextTranslateCTM (context, CGRectGetMinX(rect),// 3
                           CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);// 4
    fw = CGRectGetWidth (rect) / ovalWidth;// 5
    fh = CGRectGetHeight (rect) / ovalHeight;// 6
    
    CGContextMoveToPoint(context, fw, fh/2); // 7
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);// 8
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);// 9
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);// 10
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // 11
    CGContextClosePath(context);// 12
    
    CGContextRestoreGState(context);// 13
}