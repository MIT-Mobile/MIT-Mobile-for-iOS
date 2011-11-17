#import "LibrariesDetailTableViewCell.h"

#pragma mark - Constants
static NSString const * LibrariesDetailTitleKey = @"title";
static NSString const * LibrariesDetailAuthorKey = @"author";
static NSString const * LibrariesDetailYearKey = @"year";
static NSString const * LibrariesDetailCallNumberKey = @"call-no";
static NSString const * LibrariesDetailLibraryKey = @"sub-library";
static NSString const * LibrariesDetailISBNKey = @"isbn-issn";
#pragma mark -

@interface LibrariesDetailTableViewCell ()
@property (nonatomic,retain) NSAttributedString *textString;
@property (nonatomic,assign) CTFramesetterRef framesetter;

- (NSAttributedString*)attributedStringWithHeader:(NSString*)header
                                      displayText:(NSString*)text;
@end

@implementation LibrariesDetailTableViewCell
@synthesize bookDetails = _bookDetails;
@synthesize textString = _textString;
@dynamic framesetter;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)prepareForReuse
{
    self.bookDetails = nil;
    self.textString = nil;
    self.framesetter = nil;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter,
                                                                   CFRangeMake(0, 0),
                                                                   NULL,
                                                                   CGSizeMake(size.width,CGFLOAT_MAX),
                                                                   NULL);
    return textSize;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    CTFrameRef textFrame = CTFramesetterCreateFrame(self.framesetter,
                                                    CFRangeMake(0,0),
                                                    [path CGPath],
                                                    NULL);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, CGRectGetHeight(self.bounds));
	CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFrameDraw(textFrame, context);
    CFRelease(textFrame);
}

- (void)setBookDetails:(NSDictionary *)bookDetails
{
    if ([_bookDetails isEqualToDictionary:bookDetails] == NO)
    {
        _bookDetails = [bookDetails retain];
        self.framesetter = nil;
        self.textString = nil;
    }
}

#pragma mark - Dynamic Property Methods
- (void)setFramesetter:(CTFramesetterRef)framesetter
{
    if (_framesetter)
    {
        CFRelease(_framesetter);
    }
    
    _framesetter = (framesetter) ? CFRetain(framesetter) : NULL;
}

- (CTFramesetterRef)framesetter
{
    if (_framesetter == nil)
    {
        _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.textString);
    }
    
    return _framesetter;
}

- (NSAttributedString*)textString
{
    if (_textString == nil)
    {
        NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] init];

        UIFont *defaultBoldFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

        // Setup the title view
        {
            NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionary];
            CTFontRef titleFont = CTFontCreateWithName((CFStringRef)[defaultBoldFont fontName],
                                                       18.0,
                                                       NULL);
            [titleAttributes setObject:(id)titleFont
                             forKey:(id)kCTFontAttributeName];
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[self.bookDetails objectForKey:LibrariesDetailTitleKey]
                                                                                      attributes:titleAttributes];
            
            [detailText appendAttributedString:title];
            [title release];
            CFRelease(titleFont);
        }

        {
            NSString *author = [self.bookDetails objectForKey:LibrariesDetailAuthorKey];
            NSString *year = [self.bookDetails objectForKey:LibrariesDetailYearKey];
            NSString *displayString = [NSString stringWithFormat:@"%@; %@", year, author];
            
            [detailText appendAttributedString:[self attributedStringWithHeader:nil
                                                                    displayText:displayString]];
        }


        NSString *callNumber = [self.bookDetails objectForKey:LibrariesDetailCallNumberKey];
        if ([callNumber length])
        {
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nCall #: "
                                                                    displayText:[NSString stringWithFormat:@"%@",callNumber]]];
        }

        NSString *library = [self.bookDetails objectForKey:LibrariesDetailLibraryKey];
        if ([library length])
        {
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nLibrary: "
                                                                    displayText:[NSString stringWithFormat:@"%@",library]]];
        }

        NSArray *isbNumbers = [self.bookDetails objectForKey:LibrariesDetailISBNKey];
        if ([isbNumbers count])
        {
            NSString *isbnString = [isbNumbers componentsJoinedByString:@", "];
            [detailText appendAttributedString:[self attributedStringWithHeader:@"\nISBN: "
                                                                    displayText:isbnString]];
        }
        _textString = detailText;
    }
    return _textString;
}

- (NSAttributedString*)attributedStringWithHeader:(NSString*)header
    displayText:(NSString*)text
{
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] init];
    
    if ([header length])
    {
        UIFont *defaultBoldFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        CTFontRef boldFont = CTFontCreateWithName((CFStringRef)[defaultBoldFont fontName],
                                                  [defaultBoldFont pointSize],
                                                  NULL);
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)boldFont
                                                               forKey:(id)kCTFontAttributeName];
        NSAttributedString *headerString = [[NSAttributedString alloc] initWithString:header
                                                                           attributes:attributes];
        
        [resultString appendAttributedString:headerString];
        [headerString release];
        CFRelease(boldFont);
    }
    
    if ([text length])
    {
        UIFont *defaultFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        CTFontRef font = CTFontCreateWithName((CFStringRef)[defaultFont fontName],
                                                  [defaultFont pointSize],
                                                  NULL);
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)font
                                                               forKey:(id)kCTFontAttributeName];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:text
                                                                     attributes:attributes];
        
        [resultString appendAttributedString:string];
        [string release];
        CFRelease(font);
    }
    
    if ([resultString length])
    {
        CGFloat lineSpacing = 0.0;
        CTParagraphStyleSetting paragraphSetting = 
        {
            .spec = kCTParagraphStyleSpecifierLineSpacing,
            .valueSize = sizeof(CGFloat),
            .value = &lineSpacing
        };
        
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(&paragraphSetting, 1);
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObject:(id)paragraphStyle
                                                                   forKey:(id)kCTParagraphStyleAttributeName];
        
        [resultString addAttributes:textAttributes
                              range:NSMakeRange(0, [resultString length])];
        
        CFRelease(paragraphStyle);
    }
    
    return [resultString autorelease];
}

@end
