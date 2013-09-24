#import "MITScannerHelpViewController.h"
#import "UIKit+MITAdditions.h"

@interface MITScannerHelpViewController ()

@end

@implementation MITScannerHelpViewController
@synthesize helpTextView = _helpTextView;
@synthesize backgroundImage = _backgroundImage;
@synthesize doneButton = _doneButton;

- (id)init
{
    return [self initWithNibName:nil
                          bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"MITScannerHelpViewController"
                           bundle:nil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.backgroundImage setImage:[UIImage imageNamed:@"global/body-background"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.helpTextView = nil;
    self.backgroundImage = nil;
    self.doneButton = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)dismissHelp:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
