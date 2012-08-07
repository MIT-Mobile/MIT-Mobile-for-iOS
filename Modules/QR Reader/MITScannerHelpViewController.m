#import "MITScannerHelpViewController.h"

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)dismissHelp:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
