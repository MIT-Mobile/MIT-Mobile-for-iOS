#import "QRReaderHelpView.h"

@interface QRReaderHelpView ()
@property (nonatomic,retain) UIWebView *helpView;
@end

@implementation QRReaderHelpView
@synthesize helpView = _helpView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        NSString *fileName = nil;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            fileName = @"qr-reader-help";
        } else {
            fileName = @"qr-reader-help-no-camera";
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName
                                                         ofType:@"html"
                                                    inDirectory:@"qrreader"];
        self.helpView = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
        [self.helpView loadHTMLString:[[[NSString alloc] initWithContentsOfFile:path
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:NULL] autorelease]
                              baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        self.helpView.backgroundColor = [UIColor clearColor];
        self.helpView.opaque = NO;
        
        UIImageView *background = [[[UIImageView alloc] initWithFrame:frame] autorelease];
        background.image = [UIImage imageNamed:@"global/body-background"];
        [self addSubview:background];
        [self addSubview:self.helpView];
        self.userInteractionEnabled = NO;
    }
    return self;
}


- (void)dealloc
{
    self.helpView = nil;
    [super dealloc];
}

@end
