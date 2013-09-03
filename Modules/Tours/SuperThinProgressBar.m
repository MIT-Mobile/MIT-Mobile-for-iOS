#import "SuperThinProgressBar.h"


@implementation SuperThinProgressBar

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

    }
    return self;
}

- (void)markAsDone {
    self.currentPosition = self.numberOfSegments;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    static UIImage *background;
    static UIImage *passedImage;
    static UIImage *currentImage;
    static UIImage *dividerImage;
    
    background = [UIImage imageNamed:@"tours/progressbar_trench.png"];
    passedImage = [UIImage imageNamed:@"tours/progressbar_past.png"];
    currentImage = [UIImage imageNamed:@"tours/progressbar_current.png"];
    dividerImage = [UIImage imageNamed:@"tours/progressbar_divider.png"];
    
    [background drawAsPatternInRect:rect];
    
    if (self.numberOfSegments && self.currentPosition < self.numberOfSegments + 1) {

        CGFloat segmentLength = (rect.size.width - 4) / self.numberOfSegments;
        CGFloat passedLength = round(segmentLength * self.currentPosition);
        CGRect currentRect = CGRectMake(rect.origin.x + 2, rect.origin.y + 1, passedLength, rect.size.height - 1);
        [passedImage drawAsPatternInRect:currentRect];
        
        currentRect.origin.x += passedLength;
        currentRect.size.width = round(segmentLength);
        [currentImage drawAsPatternInRect:currentRect];
        
        CGFloat currentX = 0;
        currentRect = CGRectMake(currentX, 1, 2, 3);
        for (int i = 0; i <= self.numberOfSegments; i++) {
            [dividerImage drawInRect:currentRect];
            if (i == self.numberOfSegments - 1)
                currentX = rect.size.width - 2;
            else
                currentX += segmentLength;
            currentRect.origin.x = round(currentX);
        }
    }
}

@end
