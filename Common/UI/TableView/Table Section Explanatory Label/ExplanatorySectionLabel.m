/*
 
 Use this as a UITableView section header or footer to show explanatory text.

 With no accessoryView, its appearance is similar to footer labels in the 
 Location Services part of the iOS Settings app (i.e. "A purple location 
 services icon will appear...").
 
 With an accessoryView, its appearance is similar to the footer label in the 
 Wi-Fi part of the iOS Settings app (i.e. "Known networks will be joined...").
 
 iOS Settings like the footer for Wi-Fi settings and Location Services settings.
 
 
 Usage:

NSString * const labelText = @"Some Text";

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        ExplanatorySectionLabel *footerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
        footerLabel.text = labelText;
        return footerLabel;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        CGFloat height = [ExplanatorySectionLabel heightWithText:labelText 
                                                           width:CGRectGetWidth(tableView.bounds)
                                                            type:ExplanatorySectionFooter];
        return height;
    }
    return 0;
}
 
 */


#import "ExplanatorySectionLabel.h"
#import "UIKit+MITAdditions.h"

@interface ExplanatorySectionLabel ()

@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, assign, getter = hasCustomTextAlignment) BOOL customTextAlignment;

+ (UIFont *)labelFont;
+ (UIEdgeInsets)headerInsetsWithAccessory;
+ (UIEdgeInsets)headerInsetsWithoutAccessory;
+ (UIEdgeInsets)footerInsetsWithAccessory;
+ (UIEdgeInsets)footerInsetsWithoutAccessory;
+ (UIEdgeInsets)insetsForType:(ExplanatorySectionLabelType)type accessoryView:(UIView *)accessoryView;

@end

@implementation ExplanatorySectionLabel

- (id)initWithFrame:(CGRect)frame {
    return [self initWithType:ExplanatorySectionFooter];
}

- (id)initWithType:(ExplanatorySectionLabelType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        [self addSubview:self.label];
        _accessoryView = nil;
        _customTextAlignment = NO;
        _text = nil;
        _font = [[self class] labelFont];
        _type = type;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setAccessoryView:(UIImageView *)accessoryView {
    if (accessoryView != _accessoryView) {
        [_accessoryView removeFromSuperview];
        _accessoryView = accessoryView;
        [self addSubview:accessoryView];
        [self setNeedsLayout];
    }
}

- (void)setText:(NSString *)text {
    if (text != _text) {
        _text = [text copy];
        [self setNeedsLayout];
    }
}

- (void)setFontSize:(CGFloat)fontSize {
    if (fontSize != _fontSize) {
        _fontSize = fontSize;
        _font = [UIFont fontWithName:[[[self class] labelFont] fontName] size:fontSize];
        [self setNeedsLayout];
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    self.customTextAlignment = YES;
    [self setNeedsLayout];
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
    
    UIEdgeInsets insets = [[self class] insetsForType:self.type accessoryView:self.accessoryView];
    CGFloat imageWidth = 0;
    
    CGFloat tableWidth = self.frame.size.width;

    if (self.accessoryView) {
        imageWidth = 38.0;
        
        CGRect frame = self.accessoryView.frame;
        frame.origin.x = insets.left + floor((imageWidth - frame.size.width) / 2.0);
        frame.origin.y = insets.top;
        self.accessoryView.frame = frame;
    }
    
    CGFloat labelWidth = tableWidth - (insets.left + imageWidth + insets.right);
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    
    CGSize fittedSize = [self.text boundingRectWithSize:CGSizeMake(labelWidth, 2000.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.font, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;
    // raise the label's origin.y so the text starts at padding.height and not just the view itself
    self.label.frame = CGRectMake(
                                  insets.left + imageWidth, 
                                  insets.top - floor([self.font ascender] - [self.font capHeight]), 
                                  labelWidth, 
                                  fittedSize.height);
    self.label.text = self.text;
    self.label.font = self.font;
    self.label.backgroundColor = [UIColor clearColor];
    if (self.hasCustomTextAlignment) {
        self.label.textAlignment = self.textAlignment;
    } else {
        self.label.textAlignment = (self.accessoryView || NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    }
    self.label.lineBreakMode = NSLineBreakByWordWrapping;
    self.label.numberOfLines = 0;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.label.textColor = [UIColor colorWithHexString:@"6d6d72"];
        // no text shadow on iOS 7
    } else {
        self.label.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
        self.label.shadowColor = [UIColor whiteColor];
        self.label.shadowOffset = CGSizeMake(0, 1);
    }
}

+ (UIFont *)labelFont {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return [UIFont systemFontOfSize:14.0];
    } else {
        return [UIFont systemFontOfSize:15.0];
    }
}

+ (UIEdgeInsets)headerInsetsWithAccessory {
    return UIEdgeInsetsMake(0.0, 9.0, 15.0, 30.0);
}

+ (UIEdgeInsets)headerInsetsWithoutAccessory {
    return UIEdgeInsetsMake(0.0, 20.0, 15.0, 20.0);
}

+ (UIEdgeInsets)footerInsetsWithAccessory {
    return UIEdgeInsetsMake(15.0, 9.0, 5.0, 30.0);
}

+ (UIEdgeInsets)footerInsetsWithoutAccessory {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return UIEdgeInsetsMake(9., 15., 5., 15.);
    } else {
        return UIEdgeInsetsMake(15., 20., 5., 20.);
    }
}

+ (UIEdgeInsets)copyrightInsets {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return UIEdgeInsetsMake(15., 15., 15., 15.);
    } else {
        return UIEdgeInsetsMake(15., 20., 5., 20.);
    }
}


+ (UIEdgeInsets)insetsForType:(ExplanatorySectionLabelType)type accessoryView:(UIView *)accessoryView {
    switch (type) {
        case ExplanatorySectionHeader:
            if (accessoryView) {
                return [self headerInsetsWithAccessory];
            } else {
                return [self headerInsetsWithoutAccessory];
            }

        case ExplanatorySectionCopyright:
            return [self copyrightInsets];
        
        case ExplanatorySectionFooter:
        default:
            if (accessoryView) {
                return [self footerInsetsWithAccessory];
            } else {
                return [self footerInsetsWithoutAccessory];
            }
    }
}

+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type {
    return [self heightWithText:text width:width type:type accessoryView:nil];
}

+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type accessoryView:(UIImageView *)accessoryView {
    return [self heightWithText:text width:width type:type accessoryView:accessoryView fontSize:[[self labelFont] pointSize]];
}

+ (CGFloat)heightWithText:(NSString *)text width:(CGFloat)width type:(ExplanatorySectionLabelType)type accessoryView:(UIImageView *)accessoryView fontSize:(CGFloat)fontSize {

    UIEdgeInsets insets = [self insetsForType:type accessoryView:accessoryView];
    CGFloat imageWidth = 0;
    
    CGFloat tableWidth = width;
    if (accessoryView) {
        imageWidth = 38.0;
    }
    
    CGFloat labelWidth = tableWidth - (insets.left + imageWidth + insets.right);
    
    UIFont *labelFont = [UIFont fontWithName:[[self labelFont] fontName] size:fontSize];
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    CGSize fittedSize = [text boundingRectWithSize:CGSizeMake(labelWidth, 2000.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: labelFont, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;

    return fittedSize.height + insets.top + insets.bottom;
}

@end
