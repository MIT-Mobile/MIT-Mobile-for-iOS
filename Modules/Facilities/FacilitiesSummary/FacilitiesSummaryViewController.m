#import <QuartzCore/QuartzCore.h>

#import "FacilitiesSummaryViewController.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesConstants.h"
#import "FacilitiesRootViewController.h"

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
    
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                              style:UIBarButtonItemStyleDone
                                                             target:self
                                                             action:@selector(submitReport:)] autorelease];
    item.title = @"Submit";
    self.navigationItem.rightBarButtonItem = item;
}

- (void)viewWillAppear:(BOOL)animated {
    FacilitiesLocation *location = [self.reportData objectForKey:FacilitiesRequestLocationBuildingKey];
    FacilitiesRoom *room = [self.reportData objectForKey:FacilitiesRequestLocationRoomKey];
    NSString *customLocation = [[self.reportData objectForKey:FacilitiesRequestLocationCustomKey] lowercaseString];
    NSString *type = [[self.reportData objectForKey:FacilitiesRequestRepairTypeKey] lowercaseString];

    NSString *text = nil;
    
    if (room == nil) {
        text = [NSString stringWithFormat:@"I'm reporting a problem with the %@ %@ %@.",type,customLocation,location.name];
    } else {
        text = [NSString stringWithFormat:@"I'm reporting a problem with the %@ at %@ near room %@.",type,location.name,[room displayString]];
    }
    
    self.problemLabel.text = text;
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

- (IBAction)selectPicture:(id)sender { 
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"Take Photo",@"Choose Existing", nil] autorelease];
        sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [sheet showInView:self.view];
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *controller = [[[UIImagePickerController alloc] init] autorelease];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        controller.delegate = self;
        [self presentModalViewController:controller
                                animated:YES];
    }
}

- (IBAction)submitReport:(id)sender {
    for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[FacilitiesRootViewController class]]) {
            [self.navigationController popToViewController:controller
                                                  animated:YES];
            break;
        }
    }
}

#pragma mark -
#pragma mark Touch Handling
- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if ([event type] == UIEventTypeTouches) {
        for (UITouch *touch in touches) {
            CGPoint touchPoint = [touch locationInView:self.view];
            UIView *view = [self.view hitTest:touchPoint
                                    withEvent:event];
            NSArray *views = [NSArray arrayWithObjects:self.descriptionView,self.emailField, nil];
            
            for (UIResponder *responder in views) {
                if ((view != responder) && [responder isFirstResponder]) {
                    [responder resignFirstResponder];
                }
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerController *controller = [[[UIImagePickerController alloc] init] autorelease];
    if (buttonIndex == 0) {
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        controller.showsCameraControls = YES;
    } else if (buttonIndex == 1) {
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else if (buttonIndex == 2) {
        return;
    }
    
    controller.delegate = self;
    [self presentModalViewController:controller
                            animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (image == nil) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (image) {
        self.imageView.image = image;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
