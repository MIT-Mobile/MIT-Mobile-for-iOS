/*
 
 Use this as a UITableView section header or footer to show explanatory text.

 With no accessoryView, its appearance is similar to footer labels in the 
 Location Services part of the iOS Settings app (i.e. "A purple location 
 services icon will appear...").
 
 With an accessoryView, its appearance is similar to the footer label in the 
 Wi-Fi part of the iOS Settings app (i.e. "Known networks will be joined...").
 
 iOS Settings like the footer for Wi-Fi settings and Location Services settings.
 
 
 Usage:

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSString *labelText = @"Some text";
        CGFloat fittedHeight = [ExplanatorySectionLabel 
            heightWithText:labelText 
             accessoryView:nil
                     width:self.view.frame.size.width];
        
        ExplanatorySectionLabel *footerLabel = 
            [[ExplanatorySectionLabel alloc] 
                initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, fittedHeight)];
        footerLabel.text = labelText;
        return footerLabel;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSString *labelText = @"Some text";
        CGFloat height = [ExplanatorySectionLabel 
            heightWithText:labelText 
             accessoryView:nil 
                     width:self.view.frame.size.width];
        return height;
    }
    return 0;
}
 
 */


#import "ExplanatorySectionLabel.h"

@interface ExplanatorySectionLabel ()

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIFont *font;

+ (UIFont *)labelFont;

@end

@implementation ExplanatorySectionLabel

@synthesize accessoryView = _accessoryView;
@synthesize text = _text;
@synthesize label = _label;
@synthesize font = _font;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:frame];
        [self addSubview:self.label];
        _accessoryView = nil;
        _text = nil;
        _font = [[[self class] labelFont] retain];
    }
    return self;
}

- (void)dealloc {
    self.accessoryView = nil;
    self.label = nil;
    self.font = nil;
    self.text = nil;
    [super dealloc];
}

- (void)setAccessoryView:(UIImageView *)accessoryView {
    if (accessoryView != _accessoryView) {
        [_accessoryView removeFromSuperview];
        [_accessoryView release];
        _accessoryView = [accessoryView retain];
        [self addSubview:accessoryView];
        [self setNeedsLayout];
    }
}

- (void)setText:(NSString *)text {
    if (text != _text) {
        [_text release];
        _text = [text retain];
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    /*
     Layout with an accessoryView:
     [9-38-?-30|
     | 9px space -- icon centered in a 38 pixel space -- flexible text space -- 30px space |
     */
    /*
     Layout without an accessoryView:
     [20-?-20|
     | 20px space -- flexible text space -- 20px space |
     */
    
    CGFloat leftPadding = 20.0;
    CGFloat rightPadding = 20.0;
    CGFloat topPadding = 15.0;
    CGFloat imageWidth = 0;
    CGFloat tableWidth = self.frame.size.width;

    if (self.accessoryView) {
        leftPadding = 9.0;
        rightPadding = 30.0;
        imageWidth = 38.0;
        
        CGRect frame = self.accessoryView.frame;
        frame.origin.x = leftPadding + floor((imageWidth - frame.size.width) / 2.0);
        frame.origin.y = topPadding;
        self.accessoryView.frame = frame;
    }
    
    CGFloat labelWidth = tableWidth - (leftPadding + imageWidth + rightPadding);
    CGSize fittedSize = [self.text sizeWithFont:self.font
                              constrainedToSize:CGSizeMake(labelWidth, 2000.0)
                                  lineBreakMode:UILineBreakModeWordWrap];
    
    // raise the label's origin.y so the text starts at padding.height and not just the view itself
    self.label.frame = CGRectMake(
                                  leftPadding + imageWidth, 
                                  topPadding - floor([self.font ascender] - [self.font capHeight]), 
                                  labelWidth, 
                                  fittedSize.height);
    self.label.text = self.text;
    self.label.font = self.font;
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = (!self.accessoryView) ? UITextAlignmentCenter : UITextAlignmentLeft;
    self.label.textColor = [UIColor colorWithWhite:0.33 alpha:1.0];
    self.label.shadowColor = [UIColor whiteColor];
    self.label.shadowOffset = CGSizeMake(0, 1);
    self.label.lineBreakMode = UILineBreakModeWordWrap;
    self.label.numberOfLines = 0;
}

+ (UIFont *)labelFont {
    return [UIFont systemFontOfSize:15.0];
}

+ (CGFloat)heightWithText:(NSString *)text accessoryView:(UIImageView *)accessoryView width:(CGFloat)width {
    CGFloat leftPadding = 20.0;
    CGFloat rightPadding = 20.0;
    CGFloat topPadding = 15.0;
    CGFloat imageWidth = 0.0;
    CGFloat tableWidth = width;
    
    if (accessoryView) {
        leftPadding = 9.0;
        rightPadding = 30.0;
        imageWidth = 38.0;
    }
    
    CGFloat labelWidth = tableWidth - (leftPadding + imageWidth + rightPadding);
    
    UIFont *labelFont = [self labelFont];
    CGSize fittedSize = [text sizeWithFont:labelFont
                              constrainedToSize:CGSizeMake(labelWidth, 2000.0)
                                  lineBreakMode:UILineBreakModeWordWrap];
    
    return fittedSize.height + topPadding;
}

@end
