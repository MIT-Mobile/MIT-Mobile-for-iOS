
#import "DiningHallInfoScheduleCell.h"

#import <CoreText/CoreText.h>

@interface CTScheduleLabel : UIView
@property (nonatomic, strong) NSAttributedString * scheduleString;
@end


@implementation CTScheduleLabel

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextFillRect(context, rect);
    
    // Flip the coordinate system
    CGAffineTransform flipTransform = CGAffineTransformMake( 1, 0, 0, -1, 0, self.frame.size.height);
    CGContextConcatCTM(context, flipTransform);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect );
    
    NSAttributedString* attString = [[NSAttributedString alloc] initWithString:@"Hello world!"];
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(attString));
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                CFRangeMake(0, [attString length]), path, NULL);
    
    CTFrameDraw(frame, context);
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    
}

@end



#pragma mark -
#pragma mark DiningHallInfoScheduleCell

@interface DiningHallInfoScheduleCell ()

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) UILabel * spanLabel;
@property (nonatomic, strong) CTScheduleLabel * scheduleLabel;

@end

@implementation DiningHallInfoScheduleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.spanLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 80, 12)];        // height set for single line of text
        self.spanLabel.backgroundColor = [UIColor clearColor];
        self.spanLabel.numberOfLines = 1;
        self.spanLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        self.spanLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.spanLabel];
        
        self.scheduleLabel = [[CTScheduleLabel alloc] initWithFrame:CGRectMake(98, 10, 172, 13)];   // height set for single line, will vary in layoutSubviews
//        self.scheduleLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.scheduleLabel];
        
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
}



- (void) setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
    self.startDate = startDate;
    self.endDate = endDate;
    
    self.spanLabel.text = [self formatStringforDaySpan];
}


- (NSString *) formatStringforDaySpan
{
    if (!self.startDate) {
        return @"";
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE"];
    NSString *daySpan;
    if ([self.startDate isEqual:self.endDate]) {
        daySpan = [[df stringFromDate:self.startDate] lowercaseString];
    } else {
        daySpan = [NSString stringWithFormat:@"%@ - %@", [[df stringFromDate:self.startDate] lowercaseString], [[df stringFromDate:self.endDate] lowercaseString]];
    }
    return daySpan;
}


@end
