#import "PlaceholderTextView.h"

@interface PlaceholderTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;
@property (nonatomic, retain) UIColor *placeholderColor;

@end

@implementation PlaceholderTextView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _placeHolderLabel = nil;
    _placeholderColor = nil;
    _placeholder = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setPlaceholder:@""];
    [self setPlaceholderColor:[UIColor lightGrayColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if([_placeholder length] > 0) {
        if (!_placeHolderLabel) {
            _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,8,self.bounds.size.width,0)];
            if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
                _placeHolderLabel.frame = CGRectMake(7,9,self.bounds.size.width,0);
            }
            _placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _placeHolderLabel.numberOfLines = 0;
            _placeHolderLabel.font = self.font;
            _placeHolderLabel.backgroundColor = [UIColor clearColor];
            _placeHolderLabel.textColor = _placeholderColor;
            [self addSubview:_placeHolderLabel];
        }
        
        _placeHolderLabel.text = self.placeholder;
        [_placeHolderLabel sizeToFit];
        [self sendSubviewToBack:_placeHolderLabel];
    }
}

- (void)textChanged:(NSNotification *)notification
{
    if([self.placeholder length] > 0) {
        self.placeHolderLabel.hidden = ([self.text length] > 0);
    }
}

@end