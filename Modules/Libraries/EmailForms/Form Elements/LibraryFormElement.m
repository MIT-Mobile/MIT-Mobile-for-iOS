#import "LibraryFormElement.h"

@implementation LibraryFormElement

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel displayLabelSubtitle:(NSString *)aDisplayLabelSubtitle required:(BOOL)isRequired
{
    self = [super init];
    if (self) {
        _key = aKey;
        _displayLabel = aDisplayLabel;
        _displayLabelSubtitle = aDisplayLabelSubtitle;
        _required = isRequired;
    }
    
    return self;
}

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired
{
    return [self initWithKey:aKey displayLabel:aDisplayLabel displayLabelSubtitle:nil required:isRequired];
}

- (UITableViewCell *)tableViewCell
{
    return nil;
}

- (void)updateCell:(UITableViewCell *)tableViewCell
{
    /* Do Nothing */
}

- (CGFloat)heightForTableViewCell
{
    return 0;
}

- (UIView *)textInputView
{
    return nil;
}

- (NSString *)value
{
    return nil;
}

- (NSString *)rawDisplayLabel
{
    return _displayLabel;
}

- (NSString *)displayLabel
{
    NSString *value;
    if (self.isRequired) {
        value = _displayLabel;
    } else {
        value = [NSString stringWithFormat:@"%@ (optional)", _displayLabel];
    }
    return value;
}
@end
