#import "QRReaderHelpView.h"

@interface QRReaderHelpView ()
@property (nonatomic,retain) UIWebView *helpView;
@end

@implementation QRReaderHelpView
@synthesize helpView = _helpView;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.autoresizesSubviews = YES;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"qr-reader-help-no-camera"
                                                         ofType:@"html"
                                                    inDirectory:@"qrreader"];
        self.helpView = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
        [self.helpView loadHTMLString:[[[NSString alloc] initWithContentsOfFile:path
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:NULL] autorelease]
                              baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        self.helpView.backgroundColor = [UIColor clearColor];
        self.helpView.opaque = NO;
        self.helpView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        
        UIImageView *background = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        background.image = [UIImage imageNamed:@"global/body-background"];
        background.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        [self addSubview:background];
        [self addSubview:self.helpView];
        self.userInteractionEnabled = NO;
        
        [self setNeedsLayout];
    }
    return self;
}


- (void)dealloc
{
    self.helpView = nil;
    [super dealloc];
}

@end
