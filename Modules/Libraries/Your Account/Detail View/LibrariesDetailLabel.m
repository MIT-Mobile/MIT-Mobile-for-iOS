#import "LibrariesDetailLabel.h"
#import "UIKit+MITAdditions.h"

#pragma mark - Constants
static NSString const * LibrariesDetailTitleKey = @"title";
static NSString const * LibrariesDetailAuthorKey = @"author";
static NSString const * LibrariesDetailYearKey = @"year";
static NSString const * LibrariesDetailCallNumberKey = @"call-no";
static NSString const * LibrariesDetailLibraryKey = @"sub-library";
static NSString const * LibrariesDetailISBNKey = @"isbn-issn";
#pragma mark -

@interface LibrariesDetailLabel ()
@property (nonatomic,copy) NSAttributedString *textString;
@property (nonatomic,copy) NSDictionary *bookDetails;
@property (assign) CTFramesetterRef framesetter;

- (NSAttributedString*)attributedStringWithHeader:(NSString*)header
                                      displayText:(NSString*)text;
@end

@implementation LibrariesDetailLabel
{
    CTFramesetterRef _framesetter;
}

@dynamic framesetter;

- (id)initWithBook:(NSDictionary*)details
{
    self = [super init];
    if (self) {
        self.bookDetails = details;
        self.textInsets = UIEdgeInsetsMake(10, 5, 10, 5);
    }
    return self;
}

- (void)dealloc
{
    self.framesetter = nil;
}


- (CGSize)sizeThatFits:(CGSize)size
{
    UIEdgeInsets insets = self.textInsets;
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter,
                                                                   CFRangeMake(0, 0),
                                                                   NULL,
                                                                   CGSizeMake(size.width - (insets.left + insets.right),CGFLOAT_MAX),
                                                                   NULL);

    size.height = floor(textSize.height) + insets.top + insets.bottom + 1;
    return size;
}

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = self.textInsets;
    CGRect frame = UIEdgeInsetsInsetRect(self.bounds, insets);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];
    CTFrameRef textFrame = CTFramesetterCreateFrame(self.framesetter,
                                                    CFRangeMake(0,0),
                                                    [path CGPath],
                                                    NULL);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, CGRectGetHeight(self.bounds) + insets.top - insets.bottom);
	CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFrameDraw(textFrame, context);
    CFRelease(textFrame);
}

- (void)setBookDetails:(NSDictionary *)bookDetails
{
    if (![_bookDetails isEqual:bookDetails]) {
        _bookDetails = [bookDetails copy];
        self.framesetter = nil;
        self.textString = nil;
    }
}

#pragma mark - Dynamic Property Methods
- (void)setFramesetter:(CTFramesetterRef)framesetter
{
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    
    _framesetter = (framesetter) ? CFRetain(framesetter) : NULL;
}

- (CTFramesetterRef)framesetter
{
    if (_framesetter == nil) {
        _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.textString);
    }
    
    return _framesetter;
}

- (NSAttributedString*)textString
{
    if (self.bookDetails == nil) {
        self.textString = [[NSAttributedString alloc] init];
    } else if (_textString == nil) {
        NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] init];

        UIFont *defaultBoldFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

        // Setup the title view
        {
            CTFontRef titleFont = CTFontCreateWithName((CFStringRef)[defaultBoldFont fontName],
                                                       18.0,
                                                       NULL);

            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:self.bookDetails[LibrariesDetailTitleKey]
                                                                                      attributes:@{(NSString*)kCTFontAttributeName : (__bridge id)titleFont}];
            
            [detailText appendAttributedString:title];
            CFRelease(titleFont);
        }

        {
            NSString *author = self.bookDetails[LibrariesDetailAuthorKey];
            NSString *year = self.bookDetails[LibrariesDetailYearKey];
            NSString *displayString = [NSString stringWithFormat:@"\n%@; %@", year, author];
            
            [detailText appendAttributedString:[self attributedStringWithHeader:nil
                                                                    displayText:displayString]];
        }


        NSString *callNumber = self.bookDetails[LibrariesDetailCallNumberKey];
        if ([callNumber length])
        {
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nCall #"
                                                                    displayText:[NSString stringWithFormat:@"%@",callNumber]]];
        }
 
        NSString *library = self.bookDetails[LibrariesDetailLibraryKey];
        if ([library length])
        {
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nLibrary"
                                                                    displayText:[NSString stringWithFormat:@"%@",library]]];
        }

        NSDictionary *isbNumbers = self.bookDetails[LibrariesDetailISBNKey];
        if ([isbNumbers count])
        {
            NSString *isbnString = [isbNumbers[@"display"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nISBN"
                                                                    displayText:isbnString]];
        }
        
    
        NSString *displayAmount = self.bookDetails[@"display-amount"];
        if ([displayAmount length])
        {
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nAmount owed"
                                                                    displayText:displayAmount]];
        }
        
        
        NSNumber *fineTimestamp = self.bookDetails[@"fine-date"];
        if (fineTimestamp)
        {
            NSDate *fineDate = [NSDate dateWithTimeIntervalSince1970:[fineTimestamp doubleValue]];
            NSString *dateText = [NSDateFormatter localizedStringFromDate:fineDate
                                                                dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterNoStyle];
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nFined on"
                                                                    displayText:dateText]];
        }
        
        self.textString = detailText;
    }
    
    return _textString;
}

- (NSAttributedString*)attributedStringWithHeader:(NSString*)header
    displayText:(NSString*)text
{
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] init];
    CGFloat fontSize = 14.0;
    
    if ([header length]) {
        UIFont *defaultBoldFont = [UIFont boldSystemFontOfSize:fontSize];
        CTFontRef boldFont = CTFontCreateWithName((CFStringRef)[defaultBoldFont fontName],
                                                  [defaultBoldFont pointSize],
                                                  NULL);
        
        NSDictionary *attributes = @{(NSString*)kCTFontAttributeName : (__bridge id)boldFont};
        NSAttributedString *headerString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ",header]
                                                                           attributes:attributes];
        
        [resultString appendAttributedString:headerString];
        CFRelease(boldFont);
    }
    
    if ([text length]) {
        UIFont *defaultFont = [UIFont systemFontOfSize:fontSize];
        CTFontRef font = CTFontCreateWithName((CFStringRef)[defaultFont fontName],
                                                  [defaultFont pointSize],
                                                  NULL);
        
        NSDictionary *attributes = @{(NSString*)kCTFontAttributeName : (__bridge id)font};
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:text
                                                                     attributes:attributes];
        
        [resultString appendAttributedString:string];
        CFRelease(font);
    }
    
    if ([resultString length]) {
        CGFloat lineSpacing = 1.0;
        CGFloat paragraphSpacing = 6.0;
        CTParagraphStyleSetting paragraphSetting[] = {
            {
                .spec = kCTParagraphStyleSpecifierLineSpacing,
                .valueSize = sizeof(CGFloat),
                .value = &lineSpacing
            },
            {
                .spec = kCTParagraphStyleSpecifierParagraphSpacingBefore,
                .valueSize = sizeof(CGFloat),
                .value = &paragraphSpacing
            }
        };   
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphSetting, 2);
        NSDictionary *textAttributes = @{(NSString*)kCTParagraphStyleAttributeName : (__bridge id)paragraphStyle,
                                         (NSString*)kCTForegroundColorAttributeName : (__bridge id)[[UIColor colorWithHexString:@"#404649"] CGColor]};
        
        [resultString addAttributes:textAttributes
                              range:NSMakeRange(0, [resultString length])];
        
        CFRelease(paragraphStyle);
    }
    
    return resultString;
}

@end
