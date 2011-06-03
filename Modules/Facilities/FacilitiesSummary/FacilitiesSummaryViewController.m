#import <QuartzCore/QuartzCore.h>

#import "FacilitiesSummaryViewController.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesConstants.h"
#import "FacilitiesRootViewController.h"

enum {
    FacilitiesFocusDescription = 1,
    FacilitiesFocusEmail
};

@interface FacilitiesSummaryViewController ()
- (UIView*)firstResponderInView:(UIView*)view;
- (void)layoutOverlayView;
@end

@implementation FacilitiesSummaryViewController
@synthesize scrollView = _scrollView;
@synthesize imageView = _imageView;
@synthesize problemLabel = _problemLabel;
@synthesize descriptionView = _descriptionView;
@synthesize emailField = _emailField;
@synthesize reportData = _reportData;
@synthesize overlayView = _overlayView;
@synthesize uploadProgress = _uploadProgress;
@synthesize uploadStatus = _uploadStatus;
@synthesize returnButton = _returnButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _keyboardIsVisible = NO;
    }
    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    self.problemLabel = nil;
    self.descriptionView = nil;
    self.emailField = nil;
    self.reportData = nil;
    self.scrollView = nil;
    self.overlayView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_uploadProgress release];
    [_uploadStatus release];
    [_returnButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.scrollsToTop = NO;
    self.scrollView.contentSize = self.scrollView.bounds.size;
    
    self.imageView.image = [UIImage imageNamed:@"tours/button_photoopp"];
    self.imageView.userInteractionEnabled = NO;
    
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
    [self layoutOverlayView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    FacilitiesLocation *location = [self.reportData objectForKey:FacilitiesRequestLocationBuildingKey];
    FacilitiesRoom *room = [self.reportData objectForKey:FacilitiesRequestLocationRoomKey];
    NSString *customLocation = [self.reportData objectForKey:FacilitiesRequestLocationCustomKey];
    NSString *type = [[self.reportData objectForKey:FacilitiesRequestRepairTypeKey] lowercaseString];

    NSString *text = nil;
    
    if (location && room) {
        text = [NSString stringWithFormat:@"I'm reporting a problem with a %@ at %@ near room %@.",type,location.name,[room displayString]];
    } else if (location) {
        if ([customLocation hasSuffix:@"side"]) {
            text = [NSString stringWithFormat:@"I'm reporting a problem with a %@ %@ %@.",type,[customLocation lowercaseString],location.name];
        } else {
            text = [NSString stringWithFormat:@"I'm reporting a problem with a %@ at %@ near %@.",type,location.name,[customLocation lowercaseString]];
        }
    } else {
        text = [NSString stringWithFormat:@"I'm reporting a problem with a %@ in %@",type,customLocation];
    }
    
    self.problemLabel.text = text;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.imageView = nil;
    self.problemLabel = nil;
    self.descriptionView = nil;
    self.emailField = nil;
    self.overlayView = nil;
    self.uploadProgress = nil;
    self.uploadStatus = nil;
    self.returnButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)layoutOverlayView {
    CGRect viewFrame = self.scrollView.frame;
    viewFrame.origin = CGPointZero;
    
    UIView *overlay = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
    overlay.hidden = YES;
    overlay.backgroundColor = [UIColor colorWithWhite:0.00
                                                alpha:0.25];
    UIView *highlightView = nil;
    {
        CGFloat height = 125;
        CGRect frame = CGRectMake(25,
                (viewFrame.size.height - height) / 2,
                viewFrame.size.width - 50,
                height);
        highlightView = [[[UIView alloc] initWithFrame:frame] autorelease];
        highlightView.layer.cornerRadius = 5.0;
        highlightView.layer.borderColor = [[UIColor grayColor] CGColor];
        highlightView.layer.borderWidth = 2.0;
        highlightView.backgroundColor = [UIColor colorWithWhite:0.95
                                                          alpha:0.95];
        [overlay addSubview:highlightView];
    }

    {
        CGFloat height = 48;
        CGRect labelFrame = CGRectMake(15,
                                       15,
                                       highlightView.frame.size.width - 30,
                                       height);

        UILabel *statusLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        statusLabel.textAlignment = UITextAlignmentCenter;
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.numberOfLines = 2;
        statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        [highlightView addSubview:statusLabel];
        self.uploadStatus = statusLabel;
    }



    {
        UIProgressView *progressView = progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
        CGRect progressFrame = CGRectMake(15,
                                          ((highlightView.frame.size.height - progressView.frame.size.height) / 2.0) + 5,
                                          highlightView.frame.size.width - 30,
                                          progressView.frame.size.height);

        progressView.frame = progressFrame;
        [highlightView addSubview:progressView];
        self.uploadProgress = progressView;
    }

    {
        CGRect buttonFrame = CGRectZero;
        buttonFrame.size = CGSizeMake(128, 32);
        buttonFrame.origin = CGPointMake((highlightView.frame.size.width - buttonFrame.size.width) / 2.0,
                                         self.uploadProgress.frame.origin.y);
        UIButton *completeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        completeButton.frame = buttonFrame;
        completeButton.hidden = YES;
        [completeButton setTitle:@"Return to start"
                        forState:UIControlStateNormal];
        [completeButton addTarget:self
                           action:@selector(reportUploaded:)
                 forControlEvents:UIControlEventTouchUpInside];
        [highlightView addSubview:completeButton];
        self.returnButton = completeButton;
    }

    self.overlayView = overlay;
    [self.scrollView addSubview:overlay];
}

#pragma mark - IBAction Methods
- (IBAction)selectPicture:(id)sender {
    if (_keyboardIsVisible) {
        [self dismissKeyboard:sender];
        return;
    }

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
    if (_keyboardIsVisible) {
        return;
    }
    
    if ([self.descriptionView.text length] == 0) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Information Missing"
                                                         message:@"Please enter a description before continuing"
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil] autorelease];
        alert.tag = FacilitiesFocusDescription;
        [alert show];
        return;
    }

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.navigationItem.rightBarButtonItem.enabled = NO;
                         self.overlayView.hidden = NO;
                     }
                     completion:^ (BOOL finished) {
                         if (finished == NO) {
                             return;
                         }
                         
                         dispatch_queue_t demoQueue = dispatch_queue_create("edu.mit.mobile.ProgressDemo", 0);
                         NSUInteger imageSize = 768000; // Bytes
                         NSUInteger uploadSpeed = 50000; // Bps

                         [self.uploadProgress setProgress:0.0];
                         self.uploadProgress.hidden = NO;
                         self.returnButton.hidden = YES;
                         [self.uploadStatus setText:@"Uploading report to the server"];

                         int blkCount = 0;
                         for (NSUInteger chunk = 0; chunk < imageSize; chunk += uploadSpeed) {
                             dispatch_async(demoQueue, ^(void) {
                                 dispatch_async(dispatch_get_main_queue(), ^ {
                                     NSMutableString *string = [NSMutableString string];
                                     for (int i = 0; i < ((blkCount % 3) + 1); i++) {
                                         [string appendString:@"."];
                                     }

                                     for (int i = 0; i < (2 - (blkCount % 3)); i++) {
                                         [string appendString:@" "];
                                     }

                                     [self.uploadStatus setText:[NSString stringWithFormat:@"Uploading picture%@",string]];
                                     [self.uploadProgress setProgress:((float)chunk / (float)imageSize)];
                                 });

                                 [NSThread sleepForTimeInterval:1.0f];
                             });
                             blkCount++;
                         }

                         dispatch_async(demoQueue, ^(void) {
                             dispatch_async(dispatch_get_main_queue(), ^ {
                                 [self.uploadStatus setText:@"Successfully submitted your report"];
                                 self.uploadProgress.hidden = YES;
                                 self.returnButton.hidden = NO;
                             });
                         });

                         dispatch_release(demoQueue);
                     }];
}

- (IBAction)dismissKeyboard:(id)sender {
    if (_keyboardIsVisible) {
        UIView *firstResponder = [self firstResponderInView:self.view];

        if (firstResponder) {
            [firstResponder resignFirstResponder];
        }
    }
}

- (IBAction)reportUploaded:(id)sender {
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:0
                     animations:^{
                         self.overlayView.hidden = YES;
                     }
                     completion: ^ (BOOL finished) {
                         if (finished) {
                             for (UIViewController *controller in self.navigationController.viewControllers) {
                                 if ([controller isKindOfClass:[FacilitiesRootViewController class]]) {
                                     [self.navigationController popToViewController:controller
                                                                           animated:YES];
                                     break;
                                 }
                             }
                         }
                     }];
}

#pragma mark - UITextViewDelegate
static NSUInteger kMaxCharacters = 150;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else if ((range.length == 1) && ([text length] == 0)) {
        return YES;
    } else if ((range.location + [text length]) >= kMaxCharacters) {
        return NO;
    }
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UIActionSheetDelegate
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

#pragma mark - UIImagePickerDelegate
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case FacilitiesFocusDescription:
            [self.descriptionView becomeFirstResponder];
            break;
        case FacilitiesFocusEmail:
            [self.emailField becomeFirstResponder];
            break;
        default:
            break;
    }
}


#pragma mark - Notification Methods
- (UIView*)firstResponderInView:(UIView*)view {
    if ([view isFirstResponder]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *fr = [self firstResponderInView:subview];
        if (fr) {
            return fr;
        }
    }
    
    return nil;
}

- (void)keyboardWillShow:(NSNotification*)notification {
    NSValue *keyboard = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [self.view convertRect:[keyboard CGRectValue]
                                        fromView:nil];
    CGSize keyboardSize = keyboardRect.size;

    NSValue *durationValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];

    NSValue *curveValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    UIViewAnimationOptions options = 0;
    [curveValue getValue:&options];
    options |= UIViewAnimationOptionBeginFromCurrentState;
    options |= UIViewAnimationOptionAllowAnimatedContent;

    UIView *responder = [self firstResponderInView:self.view];
    CGRect responderRect = CGRectZero;
    if (responder) {
        responderRect = responder.frame;
        CGFloat minFrame = responderRect.origin.y + responderRect.size.height;
        if (minFrame > keyboardSize.height) {
    	    responderRect.origin.y += 10;
        }
    }

	CGRect viewFrame = self.scrollView.frame;
	viewFrame.size.height -= keyboardSize.height;

    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^ {
                         [self.scrollView setFrame:viewFrame];
                         [self.scrollView scrollRectToVisible:responderRect
                                                     animated:NO];
                     }
                     completion:nil];

    _keyboardIsVisible = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)keyboardWillHide:(NSNotification*)notification {
    NSValue *keyboardValue = [[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [keyboardValue CGRectValue];

    NSValue *durationValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];

    NSValue *curveValue = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    UIViewAnimationOptions options = 0;
    [curveValue getValue:&options];
    options |= UIViewAnimationOptionBeginFromCurrentState;
    
    CGRect visibleRect = self.scrollView.frame;
    visibleRect.size.height += keyboardRect.size.height;

    [UIView animateWithDuration:duration
                          delay:0
                        options:options
                     animations:^ {
                         [self.scrollView setFrame:visibleRect];
                     }
                     completion:^ (BOOL finished) {
                         if (finished) {
                             [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1)
                                                         animated:YES];
                         }
                     }];
    _keyboardIsVisible = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}
@end
