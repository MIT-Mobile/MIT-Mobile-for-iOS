#import <QuartzCore/QuartzCore.h>

#import "FacilitiesSummaryViewController.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesRepairType.h"
#import "FacilitiesConstants.h"
#import "FacilitiesSubmitViewController.h"
#import "PlaceholderTextView.h"
#import "MITUIConstants.h"

@interface FacilitiesSummaryViewController ()
- (UIView*)firstResponderInView:(UIView*)view;
@end

@implementation FacilitiesSummaryViewController
@synthesize scrollView = _scrollView;
@synthesize submitButton = _submitButton;
@synthesize problemLabel = _problemLabel;
@synthesize shiftingContainingView = _shiftingContainingView;
@synthesize descriptionContainingView = _descriptionContainingView;
@synthesize descriptionTextView = _descriptionTextView;
@synthesize imageView = _imageView;
@synthesize imageButton = _imageButton;
@synthesize emailField = _emailField;
@synthesize reportData = _reportData;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Detail";
    }
    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    self.problemLabel = nil;
    self.descriptionTextView = nil;
    self.emailField = nil;
    self.reportData = nil;
    self.scrollView = nil;
    self.imageButton = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    self.submitButton = [[[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                          style:UIBarButtonItemStyleDone
                                                         target:self
                                                         action:@selector(submitReport:)] autorelease];
    self.submitButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.submitButton;

    {
        self.descriptionTextView.placeholder = @"Problem Description (required)";
        self.descriptionTextView.delegate = self;
        self.descriptionTextView.layer.borderWidth = 1.0;
        self.descriptionTextView.layer.borderColor = [TABLE_SEPARATOR_COLOR CGColor];
    }

    {
//        self.imageButton.backgroundColor = [UIColor whiteColor];
//        self.imageButton.layer.cornerRadius = 10.0;
//        self.imageButton.layer.borderWidth = 1.0;
//        self.imageButton.layer.borderColor = [TABLE_SEPARATOR_COLOR CGColor];
        self.imageButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        self.imageButton.titleLabel.textColor = CELL_STANDARD_FONT_COLOR;
    }
    
    {
        self.descriptionContainingView.layer.cornerRadius = 10.0;
        self.descriptionContainingView.layer.borderWidth = 1.0;
        self.descriptionContainingView.layer.borderColor = [TABLE_SEPARATOR_COLOR CGColor];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    FacilitiesLocation *location = [self.reportData objectForKey:FacilitiesRequestLocationBuildingKey];
    FacilitiesRoom *room = [self.reportData objectForKey:FacilitiesRequestLocationRoomKey];
    FacilitiesRepairType *type = [self.reportData objectForKey:FacilitiesRequestRepairTypeKey];
    NSString *customLocation = [self.reportData objectForKey:FacilitiesRequestLocationUserBuildingKey];
    NSString *customRoom = [self.reportData objectForKey:FacilitiesRequestLocationUserRoomKey];
    NSString *typeString = [type.name lowercaseString];

    NSString *text = @"I am reporting a problem";
    
    if ([typeString compare:@"Other" options:NSCaseInsensitiveSearch] != NSOrderedSame) {
        text = [text stringByAppendingFormat:@" with a %@", typeString];
    }
    
    if (location && room) {
        
        text = [text stringByAppendingFormat:@" at %@ near room %@.",location.name,[room displayString]];
    } else if (location) {
        if ([customRoom hasSuffix:@"side"]) {
            text = [text stringByAppendingFormat:@" %@ %@.",[customRoom lowercaseString],location.name];
        } else {
            text = [text stringByAppendingFormat:@" at %@ near %@.",location.name,[customRoom lowercaseString]];
        }
    } else {
        text = [text stringByAppendingFormat:@" in %@.",customLocation];
    }
    
    self.problemLabel.text = text;
    
    CGRect frame = self.problemLabel.frame;
    CGSize fittedSize = [self.problemLabel sizeThatFits:CGSizeMake(frame.size.width, 2000.0)];
    CGFloat heightDelta = fittedSize.height - frame.size.height;
    frame.size = fittedSize;
    self.problemLabel.frame = frame;
    
    frame = self.shiftingContainingView.frame;
    frame.origin.y += heightDelta;
    self.shiftingContainingView.frame = frame;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, CGRectGetMaxY(self.shiftingContainingView.frame));
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(validateFields:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.emailField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(validateFields:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self.descriptionTextView];
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
    self.descriptionTextView = nil;
    self.emailField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - IBAction Methods
- (IBAction)selectPicture:(id)sender {
    if (_keyboardIsVisible) {
        return;
    }

    // show an "unattach photo" button if one is already set
    NSString *destructiveButtonTitle = nil;
    if ([self.reportData objectForKey:FacilitiesRequestImageKey]) {
        destructiveButtonTitle = @"Unattach Photo";
    }

    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:destructiveButtonTitle
                                               otherButtonTitles:nil] autorelease];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:@"Take Photo"];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addButtonWithTitle:@"Choose Photo"];
    }

    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showInView:self.view];
}

- (IBAction)submitReport:(id)sender {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self.reportData];
    [dictionary setObject:self.emailField.text
                   forKey:FacilitiesRequestUserEmailKey];
    [dictionary setObject:self.descriptionTextView.text
                   forKey:FacilitiesRequestUserDescriptionKey];
    self.reportData = dictionary;
    [self.navigationController pushViewController:[[[FacilitiesSubmitViewController alloc] initWithReportData:dictionary] autorelease]
                                                                           animated:YES];
}

- (IBAction)dismissKeyboard:(id)sender {
    if (_keyboardIsVisible) {
        UIView *firstResponder = [self firstResponderInView:self.view];
        
        if (firstResponder) {
            [firstResponder resignFirstResponder];
        }
    }
}


#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([trimmedText length] == 0) {
            textView.text = nil;
        } else {
            textView.text = trimmedText;
        }
        
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:UITextViewTextDidChangeNotification
                                                                                             object:textView]];
        return NO;
    }
    
    return YES;
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *trimmedText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([trimmedText length] == 0) {
        textField.text = nil;
    } else {
        textField.text = trimmedText;
    }
    
    [textField resignFirstResponder];
    return NO;
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        return;
    } else if ([buttonTitle isEqualToString:@"Unattach Photo"]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self.reportData];
        [dictionary removeObjectForKey:FacilitiesRequestImageKey];
        self.reportData = dictionary;
        
        if (self.imageView.hidden == NO) {
            // resize description field to fill area previously taken by attached photo
            CGRect textFrame = self.descriptionTextView.frame;
            CGRect imageFrame = self.imageView.frame;
            textFrame.size.width += imageFrame.size.width;
            self.descriptionTextView.frame = textFrame;
        }
        
        self.imageView.image = nil;
        self.imageView.hidden = YES;
        
        [self.imageButton setTitle:@"Attach Photo" forState:UIControlStateNormal];
    } else {
        UIImagePickerController *controller = [[[UIImagePickerController alloc] init] autorelease];
        if ([buttonTitle isEqualToString:@"Take Photo"]) {
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.showsCameraControls = YES;
        } else if ([buttonTitle isEqualToString:@"Choose Photo"]) {
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        controller.delegate = self;
        [self.navigationController presentModalViewController:controller
                                                     animated:YES];
    }    
}

#pragma mark - UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (image == nil) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (image) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self.reportData];
        [dictionary setObject:image
                       forKey:FacilitiesRequestImageKey];
        self.reportData = dictionary;

        if (self.imageView.hidden == YES) {
            // resize description field to make room for the attached photo
            CGRect textFrame = self.descriptionTextView.frame;
            CGRect imageFrame = self.imageView.frame;
            textFrame.size.width -= imageFrame.size.width;
            self.descriptionTextView.frame = textFrame;
            
            [self.imageButton setTitle:@"Change Photo" forState:UIControlStateNormal];
        }
        
        self.imageView.image = image;
        self.imageView.hidden = NO;
    } else {
        if (self.imageView.hidden == NO) {
            // resize description field to fill area previously taken by attached photo
            CGRect textFrame = self.descriptionTextView.frame;
            CGRect imageFrame = self.imageView.frame;
            textFrame.size.width += imageFrame.size.width;
            self.descriptionTextView.frame = textFrame;
        }
        
        self.imageView.image = nil;
        self.imageView.hidden = YES;
    }
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Notification Methods
- (void)validateFields:(NSNotification*)notification {
    BOOL enableSubmit = NO;
    
    NSString *checkString = [self.descriptionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([checkString length] > 0) {
        enableSubmit = YES;
    }
    
    checkString = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([checkString length] == 0) {
        enableSubmit = NO;
    }
    
    self.submitButton.enabled = enableSubmit;
}

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
        responderRect = [self.scrollView convertRect:responder.frame fromView:responder.superview];
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
}
@end
