#import <QuartzCore/QuartzCore.h>

#import "FacilitiesSummaryViewController.h"


@implementation FacilitiesSummaryViewController
@synthesize imageView = _imageView;
@synthesize pictureButton = _pictureButton;
@synthesize problemLabel = _problemLabel;
@synthesize descriptionView = _descriptionView;
@synthesize emailField = _emailField;
@synthesize characterCount = _characterCount;
@synthesize reportData = _reportData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    self.pictureButton = nil;
    self.problemLabel = nil;
    self.descriptionView = nil;
    self.emailField = nil;
    self.characterCount = nil;
    self.reportData = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.imageView.image = [UIImage imageNamed:@"tours/button_photoopp"];
    
    self.descriptionView.layer.cornerRadius = 5.0f;
    self.descriptionView.layer.borderWidth = 2.0f;
    self.descriptionView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.descriptionView.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.imageView = nil;
    self.pictureButton = nil;
    self.problemLabel = nil;
    self.descriptionView = nil;
    self.emailField = nil;
    self.characterCount = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Touch Handling
- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if ([event type] == UIEventTypeTouches) {
        for (UITouch *touch in touches) {
            CGPoint touchPoint = [touch locationInView:self.view];
            if (!CGRectContainsPoint(self.descriptionView.frame, touchPoint)) {
                [self.descriptionView resignFirstResponder];
                return;
            }
        }
    }
    
    [super touchesBegan:touches
              withEvent:event];
}


#pragma mark -
#pragma mark UITextViewDelegate
static NSUInteger kMaxCharacters = 150;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ((range.length == 1) && ([text length] == 0)) {
        return YES;
    } else if ((range.location + [text length]) >= kMaxCharacters) {
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.characterCount setText:[NSString stringWithFormat:@"%3u/%03u",[textView.text length],kMaxCharacters]];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}
@end
