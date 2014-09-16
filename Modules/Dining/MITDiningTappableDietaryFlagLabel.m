/***********************************************************************************
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 Matthew Styles
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 ***********************************************************************************/

#import "MITDiningTappableDietaryFlagLabel.h"


#pragma mark - Private Interface

@interface MITDiningTappableDietaryFlagLabel ()

// Used to control layout of glyphs and rendering
@property (nonatomic, retain) NSLayoutManager *layoutManager;

// Specifies the space in which to render text
@property (nonatomic, retain) NSTextContainer *textContainer;

// Backing storage for text that is rendered by the layout manager
@property (nonatomic, retain) NSTextStorage *textStorage;

@property (nonatomic, assign) BOOL isTouchMoved;

@end


#pragma mark - Implementation

@implementation MITDiningTappableDietaryFlagLabel

#pragma mark - Construction

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupTextSystem];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setupTextSystem];
    }
    return self;
}

// Common initialisation. Must be done once during construction.
- (void)setupTextSystem
{
    // Create a text container and set it up to match our label properties
    self.textContainer = [[NSTextContainer alloc] init];
    self.textContainer.lineFragmentPadding = 0;
    self.textContainer.maximumNumberOfLines = self.numberOfLines;
    self.textContainer.lineBreakMode = self.lineBreakMode;
    self.textContainer.size = self.frame.size;
    
    // Create a layout manager for rendering
    self.layoutManager = [[NSLayoutManager alloc] init];
    self.layoutManager.delegate = self;
    [self.layoutManager addTextContainer:self.textContainer];
    
    // Attach the layou manager to the container and storage
    [self.textContainer setLayoutManager:self.layoutManager];
    
    // Make sure user interaction is enabled so we can accept touches
    self.userInteractionEnabled = YES;
    
    // Establish the text store with our current text
    [self updateTextStoreWithText];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    [super setNumberOfLines:numberOfLines];
    
    self.textContainer.maximumNumberOfLines = numberOfLines;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    // Pass the text to the super class first
    [super setAttributedText:attributedText];
    
    [self updateTextStoreWithAttributedString:attributedText];
}

#pragma mark - Text Storage Management

- (void)updateTextStoreWithText
{
    // Now update our storage from either the attributedString or the plain text
    [self updateTextStoreWithAttributedString:self.attributedText];
    
    [self setNeedsDisplay];
}

- (void)updateTextStoreWithAttributedString:(NSAttributedString *)attributedString
{
    if (attributedString.length != 0) {
        attributedString = [MITDiningTappableDietaryFlagLabel sanitizeAttributedString:attributedString];
    }
    
    if (self.textStorage) {
        // Set the string on the storage
        [self.textStorage setAttributedString:attributedString];
    } else {
        // Create a new text storage and attach it correctly to the layout manager
        self.textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
        [self.textStorage addLayoutManager:self.layoutManager];
        [self.layoutManager setTextStorage:self.textStorage];
    }
}

#pragma mark - Layout and Rendering

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    // Use our text container to calculate the bounds required. First save our
    // current text container setup
    CGSize savedTextContainerSize = self.textContainer.size;
    NSInteger savedTextContainerNumberOfLines = self.textContainer.maximumNumberOfLines;
    
    // Apply the new potential bounds and number of lines
    self.textContainer.size = bounds.size;
    self.textContainer.maximumNumberOfLines = numberOfLines;
    
    // Measure the text with the new state
    CGRect textBounds;
    @try
    {
        NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
        textBounds = [self.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
        
        // Position the bounds and round up the size for good measure
        textBounds.origin = bounds.origin;
        textBounds.size.width = ceilf(textBounds.size.width);
        textBounds.size.height = ceilf(textBounds.size.height);
    }
    @finally
    {
        // Restore the old container state before we exit under any circumstances
        self.textContainer.size = savedTextContainerSize;
        self.textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines;
    }
    
    return textBounds;
}

- (void)drawTextInRect:(CGRect)rect
{
    // Don't call super implementation. Might want to uncomment this out when
    // debugging layout and rendering problems.
    //        [super drawTextInRect:rect];
    
    // Calculate the offset of the text in the view
    CGPoint textOffset;
    NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
    
    // Drawing code
    [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOffset];
    [self.layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:textOffset];
}

// Returns the XY offset of the range of glyphs from the view's origin
- (CGPoint)calcTextOffsetForGlyphRange:(NSRange)glyphRange
{
    CGPoint textOffset = CGPointZero;
    
    CGRect textBounds = [self.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    CGFloat paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2.0f;
    if (paddingHeight > 0)
    {
        textOffset.y = paddingHeight;
    }
    
    return textOffset;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.textContainer.size = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.textContainer.size = self.bounds.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Update our container size when the view frame changes
    self.textContainer.size = self.bounds.size;
}


#pragma mark - Interactions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isTouchMoved = NO;
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    self.isTouchMoved = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    // If the user dragged their finger we ignore the touch
    if (self.isTouchMoved) {
        return;
    }
    
    // Do nothing if we have no text
    if (self.textStorage.string.length == 0) {
        return;
    }
    
    // Get the info for the touched link if there is one
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    
    // Work out the offset of the text in the view
    CGPoint textOffset;
    NSRange glyphRange = [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    textOffset = [self calcTextOffsetForGlyphRange:glyphRange];
    
    // Get the touch location and use text offset to convert to text cotainer coords
    touchLocation.x -= textOffset.x;
    touchLocation.y -= textOffset.y;
    
    NSUInteger touchedChar = [self.layoutManager glyphIndexForPoint:touchLocation inTextContainer:self.textContainer];
    
    // If the touch is in white space after the last glyph on the line we don't
    // count it as a hit on the text
    NSRange lineRange;
    CGRect lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:touchedChar effectiveRange:&lineRange];
    if (CGRectContainsPoint(lineRect, touchLocation) == NO)
    {
        return;
    }
    
    
    
    if ([self characterAtIndexIsFlagAttachment:touchedChar]) {
        if ([self.delegate respondsToSelector:@selector(dietaryFlagTappedInLabel:withPopoverRect:)]) {
            [self.delegate dietaryFlagTappedInLabel:self withPopoverRect:[self rectForDietaryFlags]];
        }
    }
}

- (BOOL)characterAtIndexIsFlagAttachment:(NSUInteger)characterIndex
{
    NSMutableArray *dietaryFlagAttachmentRanges = [NSMutableArray array];
    
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, self.attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:NSAttachmentAttributeName]) {
            [dietaryFlagAttachmentRanges addObject:[NSValue valueWithRange:range]];
        }
    }];
    
    for (NSValue *dietaryFlagAttachmentRangeValue in dietaryFlagAttachmentRanges) {
        NSRange dietaryFlagAttachmentRange = [dietaryFlagAttachmentRangeValue rangeValue];
        if (characterIndex >= dietaryFlagAttachmentRange.location && characterIndex < (dietaryFlagAttachmentRange.location + dietaryFlagAttachmentRange.length)) {
            return YES;
        }
    }
    
    return NO;
}

// Note: This rect will not be very useful if the dietary flags span more than one line. Considering the current app requirements specifically indicate that this is not allowed,
// I am leaving this without a solution. Simple solutions would be to check if the flags span more than one line, and then return either the rect for the first flag, last flag, first line, or last line
- (CGRect)rectForDietaryFlags
{
    __block BOOL foundFlag = NO;
    __block NSRange firstFlagCharacterRange;
    __block NSRange lastFlagCharacterRange;
    
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, self.attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:NSAttachmentAttributeName]) {
            if (!foundFlag) {
                foundFlag = YES;
                firstFlagCharacterRange = range;
            }
            lastFlagCharacterRange = range;
        }
    }];
    
    if (foundFlag) {
        NSRange flagsGlyphRange = [self.layoutManager glyphRangeForCharacterRange:NSMakeRange(firstFlagCharacterRange.location, (lastFlagCharacterRange.location - firstFlagCharacterRange.location) + lastFlagCharacterRange.length) actualCharacterRange:NULL];
        return [self.layoutManager boundingRectForGlyphRange:flagsGlyphRange inTextContainer:self.textContainer];
    } else {
        return CGRectNull;
    }
}

#pragma mark - Layout manager delegate

- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
{
    // Don't allow line breaks inside URLs
    NSRange range;
    NSURL *linkURL = [layoutManager.textStorage attribute:NSLinkAttributeName
                                                  atIndex:charIndex
                                           effectiveRange:&range];
    
    return !(linkURL && (charIndex > range.location) && (charIndex <= NSMaxRange(range)));
}

+ (NSAttributedString *)sanitizeAttributedString:(NSAttributedString *)attributedString
{
    // Setup paragraph alignement properly. IB applies the line break style
    // to the attributed string. The problem is that the text container then
    // breaks at the first line of text. If we set the line break to wrapping
    // then the text container defines the break mode and it works.
    // NOTE: This is either an Apple bug or something I've misunderstood.
    
    // Get the current paragraph style. IB only allows a single paragraph so
    // getting the style of the first char is fine.
    NSRange range;
    NSParagraphStyle *paragraphStyle = [attributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&range];
    
    if (paragraphStyle == nil) {
        return attributedString;
    }
    
    // Remove the line breaks
    NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
    mutableParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    // Apply new style
    NSMutableAttributedString *restyled = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    [restyled addAttribute:NSParagraphStyleAttributeName value:mutableParagraphStyle range:NSMakeRange(0, restyled.length)];
    
    return restyled;
}


@end