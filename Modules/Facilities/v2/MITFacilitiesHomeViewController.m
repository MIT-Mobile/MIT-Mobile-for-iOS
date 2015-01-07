#import "MITFacilitiesHomeViewController.h"
#import "MITBuildingServicesReportForm.h"
#import "MITActionSheetHandler.h"
#import "MITNavigationController.h"

#import "FacilitiesSubmitViewController.h"
#import "FacilitiesCategoryViewController.h"
#import "FacilitiesTypeViewController.h"
#import "FacilitiesRoomViewController.h"
#import "FacilitiesPropertyOwner.h"
#import "FacilitiesConstants.h"

#import "UIKit+MITAdditions.h"
#import "UIImage+Metadata.h"
#import "NSString+EmailValidation.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "SVProgressHUD.h"
#import "MITTelephoneHandler.h"

typedef NS_ENUM(NSUInteger, MITFacilitiesFormFieldType) {
    MITFacilitiesFormFieldEmail = 0,
    MITFacilitiesFormFieldLocation,
    MITFacilitiesFormFieldRoom,
    MITFacilitiesFormFieldProblemType,
    MITFacilitiesFormFieldDescription,
    MITFacilitiesFormFieldAttachPhoto,
    MITFacilitiesFormFieldLeasedMessage,
    MITFacilitiesFormFieldMaintainer,
    MITFacilitiesFormFieldMaintainerPhone
};

typedef NS_ENUM(NSUInteger, MITLeasedFacilitiesFormFieldType) {
    MITLeasedFacilitiesFormFieldEmail = 0,
    MITLeasedFacilitiesFormFieldLocation,
    MITLeasedFacilitiesFormFieldLeasedMessage,
    MITLeasedFacilitiesFormFieldMaintainer,
    MITLeasedFacilitiesFormFieldMaintainerPhone,
    MITLeasedFacilitiesFormFieldMaintainerEmail
};

static NSString* const kFacilitiesEmailAddress = @"txtdof@mit.edu";
static NSString* const kFacilitiesPhoneNumber = @"(617) 253-4948";

static NSInteger const kNumberOfFieldsWithRoom = 6;
static NSInteger const kNumberOfFieldsWithoutRoom = 5;

@interface MITFacilitiesHomeViewController () <UITableViewDataSource, UITextViewDelegate, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *contactFacilitiesButton;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (nonatomic, strong) UIBarButtonItem *submitButton;
@property (nonatomic, strong) UIPopoverController *facilitiesPopoverController;

@property (nonatomic, strong) MITBuildingServicesReportForm *reportForm;

@property (nonatomic, strong) UITextView *editingTextView;
@property (nonatomic, strong) NSIndexPath *editingIndexPath;
@property (nonatomic, assign) BOOL isKeyboardUp;

@property (nonatomic, strong) MITActionSheetHandler *actionSheetHandler;

@end

@implementation MITFacilitiesHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // setup reportForm as a shared object within the module
    self.reportForm = [MITBuildingServicesReportForm sharedServiceReport];
    [self.reportForm clearAll];
    
    // initialize properties
    self.editingTextView = nil;
    self.editingIndexPath = nil;
    
    // make sure tableView has no extra separator lines at the bottom
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // set the target action for the main facilities button
    [self.contactFacilitiesButton addTarget:self action:@selector(contactFacilitiesAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // initialize submit button
    self.submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                         style:UIBarButtonItemStyleDone
                                                        target:self
                                                        action:@selector(submitReport)];
    self.submitButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.submitButton;
    
    // view title
    self.title = @"Building Services";
    
    // this is nil for iPhone
    if( self.emailLabel != nil )
    {
        [self.emailLabel setFont:[UIFont systemFontOfSize:14]];
        [self.emailLabel setTextColor:[UIColor mit_tintColor]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChooseLocation:) name:MITBuildingServicesLocationChosenNoticiation object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditing)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    [self validateFields];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.editingTextView resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - actions

- (void)submitReport
{
    [self.view endEditing:YES];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:@"Submitting..." maskType:SVProgressHUDMaskTypeGradient];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.reportForm submitFormWithCompletionBlock:^(NSDictionary *responseObject, NSError *error) {
            if( error == nil )
            {
                [SVProgressHUD showSuccessWithStatus:@"Report submitted successfully"];
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                {
                    [self.reportForm clearAll];
                    [self.tableView reloadData];
                    
                    [SVProgressHUD dismiss];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"Submission Failed"
                                                                           message:@"Unable to submit report. Please try again later."
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                    [failureAlert show];
                });
            }
        } progressUpdateBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            [SVProgressHUD showProgress:(totalBytesWritten / totalBytesExpectedToWrite) status:@"Submitting..." maskType:SVProgressHUDMaskTypeGradient];
        }];
    });
}

- (void)contactFacilitiesAction:(id)sender
{
    __weak MITFacilitiesHomeViewController *weakSelf = self;
    
    self.actionSheetHandler = [MITActionSheetHandler new];
    [self.actionSheetHandler setActionSheetTintColor:[UIColor mit_tintColor]];
    
    self.actionSheetHandler.delegateBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex)
    {
        if( buttonIndex == actionSheet.cancelButtonIndex )
        {
            return;
        }
        
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if([title hasPrefix:@"Call"])
        {
            [MITTelephoneHandler attemptToCallPhoneNumber:kFacilitiesPhoneNumber];
        }
        else
        {
            // email
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                [mailView setMailComposeDelegate:weakSelf];
                [mailView setSubject:@"Request from Building Services"];
                [mailView setToRecipients:[NSArray arrayWithObject:kFacilitiesEmailAddress]];
                [weakSelf presentViewController:mailView animated:YES completion:NULL];
            }
        }
    };
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self.actionSheetHandler
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:[NSString stringWithFormat:@"Call %@", kFacilitiesPhoneNumber], [NSString stringWithFormat:@"Email %@", kFacilitiesEmailAddress], nil];
    [actionSheet showInView:self.view];
}

- (void)removePhotoAction:(UIButton *)senderButton
{
    __weak MITFacilitiesHomeViewController *weakSelf = self;
    
    self.actionSheetHandler = [MITActionSheetHandler new];
    [self.actionSheetHandler setActionSheetTintColor:[UIColor mit_tintColor]];
    self.actionSheetHandler.delegateBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex)
    {
        if( buttonIndex == actionSheet.cancelButtonIndex )
        {
            return;
        }
        
        [[MITBuildingServicesReportForm sharedServiceReport] setReportImage:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            
            [weakSelf validateFields];
        });
    };
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self.actionSheetHandler
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Remove Photo"
                                                    otherButtonTitles:nil];

    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        [actionSheet showInView:self.view];
    }
    else
    {
        CGRect senderFrame = [senderButton convertRect:senderButton.bounds toView:self.view];
        [actionSheet showFromRect:senderFrame inView:self.view animated:YES];
    }
}

- (void)attachPhotoAction:(UIButton *)senderButton
{
    __weak MITFacilitiesHomeViewController *weakSelf = self;
    
    self.actionSheetHandler = [MITActionSheetHandler new];
    [self.actionSheetHandler setActionSheetTintColor:[UIColor mit_tintColor]];
    self.actionSheetHandler.delegateBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex)
    {
        if( buttonIndex == actionSheet.cancelButtonIndex )
        {
            return;
        }
        
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        
        if( buttonIndex == 0 )
        {
            // take photo
            
            if( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
            {
                UIAlertView *warningAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                           message:@"Device has no camera"
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                
                [warningAlertView show];
                
                return;
            }
            
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.showsCameraControls = YES;
        }
        else
        {
            // choose photo
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        
        controller.delegate = weakSelf;
        [weakSelf.navigationController presentViewController:controller animated:YES completion:NULL];
    };
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self.actionSheetHandler
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take Photo", @"Choose Photo", nil];

    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        [actionSheet showInView:self.view];
    }
    else
    {
        CGRect senderFrame = [senderButton convertRect:senderButton.bounds toView:self.view];
        [actionSheet showFromRect:senderFrame inView:self.view animated:YES];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didChooseLocation:(NSNotification *)notification
{
    if( self.facilitiesPopoverController != nil )
    {
        [self.facilitiesPopoverController dismissPopoverAnimated:YES];
        
        [self.tableView reloadData];
    }
}

#pragma mark - tableview stuff

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSInteger defaultHeight = 72;
    
    CGFloat height = defaultHeight;
    
    if( [self.reportForm.location.isLeased boolValue] )
    {
        height = [self leasedFacilityTableView:tableView heightForRowAtIndexPath:indexPath defaultHeight:defaultHeight];
    }
    else
    {
        height = [self regularFacilityTableView:tableView heightForRowAtIndexPath:indexPath defaultHeight:defaultHeight];
    }
    
    return height;
}

- (CGFloat)regularFacilityTableView:(UITableView *)tableView
            heightForRowAtIndexPath:(NSIndexPath *)indexPath
                      defaultHeight:(NSInteger)defaultHeight
{
    BOOL isEditingRow = indexPath.row == self.editingIndexPath.row;
    
    NSInteger row = [self adjustedFieldRow:indexPath.row];
    
    if( self.editingTextView != nil && isEditingRow && row == MITFacilitiesFormFieldDescription )
    {
        CGSize size = [self.editingTextView sizeThatFits:CGSizeMake(self.editingTextView.frame.size.width, FLT_MAX)];
        
        return (defaultHeight - 20) + size.height;
    }
    else if( row == MITFacilitiesFormFieldAttachPhoto && self.reportForm.reportImage != nil )
    {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 450 : 553;
    }
    
    return defaultHeight;
}

- (CGFloat)leasedFacilityTableView:(UITableView *)tableView
           heightForRowAtIndexPath:(NSIndexPath *)indexPath
                     defaultHeight:(NSInteger)defaultHeight
{
    if( (indexPath.row == MITLeasedFacilitiesFormFieldLeasedMessage) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) )
    {
        return defaultHeight + 20;
    }
    
    return defaultHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfFormFields];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if( [self.reportForm.location.isLeased boolValue] )
    {
        cell = [self tableView:tableView leasedFacilitiesAttributeCellForRowAtIndexPath:indexPath];
    }
    else if( indexPath.row == [self lastRowIndex] )
    {
        // action cell
        cell = [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
    }
    else
    {
        cell = [self tableView:tableView attributeCellForRowAtIndexPath:indexPath];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
    
    UIButton *attachPhotoBtn = (UIButton *)[cell viewWithTag:1];
    [attachPhotoBtn setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
    [attachPhotoBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    if( self.reportForm.reportImage != nil )
    {
        [attachPhotoBtn setTitle:@"Remove Photo" forState:UIControlStateNormal];
        [attachPhotoBtn addTarget:self action:@selector(removePhotoAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [attachPhotoBtn setTitle:@"Attach Photo" forState:UIControlStateNormal];
        [attachPhotoBtn addTarget:self action:@selector(attachPhotoAction:) forControlEvents:UIControlEventTouchUpInside];
    }

    // image attachment
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:2];
    if( self.reportForm.reportImage != nil )
    {
        imageView.image = self.reportForm.reportImage;
    }
    else
    {
        imageView.image = nil;
    }
    
    cell.separatorInset = UIEdgeInsetsMake(0, 1000.0, 0, 0);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView attributeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSInteger row = [self adjustedFieldRow:indexPath.row];
    
    switch (row) {
        case MITFacilitiesFormFieldEmail:
            cell = [self emailFieldCellWithIndexPath:indexPath];
            break;
        case MITFacilitiesFormFieldLocation:
            cell = [self locationFieldCellWithIndexPath:indexPath];
            break;
        case MITFacilitiesFormFieldRoom:
            cell = [self roomFieldCellWithIndexPath:indexPath];
            break;
        case MITFacilitiesFormFieldProblemType:
            cell = [self problemTypeFieldCellWithIndexPath:indexPath];
            break;
        case MITFacilitiesFormFieldDescription:
            cell = [self descriptionFieldCellWithIndexPath:indexPath];
            break;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView leasedFacilitiesAttributeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case MITLeasedFacilitiesFormFieldEmail:
            cell = [self emailFieldCellWithIndexPath:indexPath];
            break;
        case MITLeasedFacilitiesFormFieldLocation:
            cell = [self locationFieldCellWithIndexPath:indexPath];
            break;
        case MITLeasedFacilitiesFormFieldLeasedMessage:
            cell = [self leasedMessageCellWithIndexPath:indexPath];
            break;
        case MITLeasedFacilitiesFormFieldMaintainer:
            cell = [self leasedMaintainerCellWithIndexPath:indexPath];
            break;
        case MITLeasedFacilitiesFormFieldMaintainerPhone:
            cell = [self leasedMaintainerPhoneCellWithIndexPath:indexPath];
            break;
    }
    
    if( indexPath.row == [self lastRowIndex] )
    {
        cell.separatorInset = UIEdgeInsetsMake(0.f, 1000.0, 0.f, 0.f);
    }
    
    return cell;
}

- (MITFacilitiesEditableFieldCell *)emailFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeEditableCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.titleLabel.text = @"email";
    
    cell.subtitleTextView.text = self.reportForm.email;
    cell.subtitleTextView.delegate = self;
    cell.subtitleTextView.keyboardType = UIKeyboardTypeEmailAddress;
    cell.subtitleTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.subtitleTextView.spellCheckingType = UITextSpellCheckingTypeNo;
    
    return cell;
}

- (UITableViewCell *)locationFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *locationCell = nil;
    
    NSString *locationName = self.reportForm.location != nil ? self.reportForm.location.displayString : self.reportForm.customLocation;
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        MITFacilitiesEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeEditableCell" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.titleLabel.text = @"location";
        cell.subtitleTextView.text = locationName;

        cell.subtitleTextView.delegate = self;
        cell.subtitleTextView.userInteractionEnabled = NO;
        
        locationCell = cell;
    }
    else
    {
        MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell"
                                                                                       forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.titleLabel.text = @"location";
        cell.subtitleLabel.text = locationName;
        
        locationCell = cell;
    }
    
    return locationCell;
}

- (UITableViewCell *)roomFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *roomCell = nil;
    
    NSString *roomName = self.reportForm.room == nil ? self.reportForm.roomAltName : self.reportForm.room.displayString;
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        MITFacilitiesEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeEditableCell" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;

        cell.titleLabel.text = @"room";
        cell.subtitleTextView.text = roomName;
        
        cell.subtitleTextView.delegate = self;
        cell.subtitleTextView.userInteractionEnabled = NO;
        
        roomCell = cell;
    }
    else
    {
        MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.titleLabel.text = @"room";
        cell.subtitleLabel.text = roomName;
        
        roomCell = cell;
    }
    
    return roomCell;
}

- (MITFacilitiesNonEditableFieldCell *)problemTypeFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    
    cell.accessoryType = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    cell.titleLabel.text = @"problem type";
    cell.subtitleLabel.text = self.reportForm.problemType.name;
    
    return cell;
}

- (MITFacilitiesEditableFieldCell *)descriptionFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.titleLabel.text = @"description";
    
    cell.subtitleTextView.delegate = self;
    cell.subtitleTextView.userInteractionEnabled = YES;
    
    cell.subtitleTextView.text = self.reportForm.reportDescription;
    cell.subtitleTextView.keyboardType = UIKeyboardTypeDefault;
    
    return cell;
}

- (MITFacilitiesLeasedMessageCell *)leasedMessageCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesLeasedMessageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MITFacilitiesLeasedMessageCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"The Department of Facilities is not responsible for the maintenance of %@. Please contact %@ to report any issues.", [self.reportForm.location displayString], self.reportForm.location.propertyOwner.name];
    
    
    return cell;
}

- (MITFacilitiesNonEditableFieldCell *)leasedMaintainerCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.titleLabel.text = @"maintainer";
    cell.subtitleLabel.text = self.reportForm.location.propertyOwner.name;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (MITFacilitiesNonEditableFieldCell *)leasedMaintainerPhoneCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if( self.reportForm.location.propertyOwner.phone.length > 0 )
    {
        cell.titleLabel.text = @"phone";
        
        NSString *phoneString = self.reportForm.location.propertyOwner.phone;
        phoneString = [NSString stringWithFormat:@"%@-%@-%@",
                       [phoneString substringToIndex:3],
                       [phoneString substringWithRange:NSMakeRange(3, 3)],
                       [phoneString substringFromIndex:6]];
        cell.subtitleLabel.text = phoneString;
    }
    else if( self.reportForm.location.propertyOwner.email.length > 0 )
    {
        cell.titleLabel.text = @"email";
        cell.subtitleLabel.text = self.reportForm.location.propertyOwner.email;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIViewController *vc = nil;
    
    NSInteger row = [self adjustedFieldRow:indexPath.row];
    
    if( row == MITFacilitiesFormFieldAttachPhoto )
    {
        return;
    }
    
    self.editingIndexPath = indexPath;
    
    if( row == MITFacilitiesFormFieldLocation )
    {
        vc = [[FacilitiesCategoryViewController alloc] init];
        
        if( [cell isKindOfClass:[MITFacilitiesEditableFieldCell class]] )
        {
            MITFacilitiesEditableFieldCell *locationCell = (MITFacilitiesEditableFieldCell *)cell;
            [locationCell.subtitleTextView becomeFirstResponder];
        }
    }
    else if( row == MITFacilitiesFormFieldProblemType )
    {
        vc = [[FacilitiesTypeViewController alloc] init];
    }
    else if( row == MITFacilitiesFormFieldRoom )
    {
        FacilitiesRoomViewController *fvc = [[FacilitiesRoomViewController alloc] init];
        fvc.location = self.reportForm.location;
        
        vc = fvc;
        
        if( [cell isKindOfClass:[MITFacilitiesEditableFieldCell class]] )
        {
            MITFacilitiesEditableFieldCell *roomCell = (MITFacilitiesEditableFieldCell *)cell;
            [roomCell.subtitleTextView becomeFirstResponder];
        }
    }
    
    if( vc == nil )
    {
        return;
    }
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        if( [self.facilitiesPopoverController isPopoverVisible] )
        {
            [self presentFacilitiesPopoverAtIndexPath:indexPath];
            return;
        }
        
        MITNavigationController *navController = [[MITNavigationController alloc] initWithRootViewController:vc];
        
        navController.delegate = self;
        
        self.facilitiesPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.facilitiesPopoverController.delegate = self;
        self.facilitiesPopoverController.backgroundColor = [UIColor whiteColor];
        self.facilitiesPopoverController.passthroughViews = @[cell];
        [self presentFacilitiesPopoverAtIndexPath:indexPath];
    }
    else
    {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - navigation controller and popover controller delegates

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if( [viewController isKindOfClass:[FacilitiesCategoryViewController class]] ||
        [viewController isKindOfClass:[FacilitiesRoomViewController class]] )
    {
        return;
    }
    
    [self.view endEditing:YES];
    
    if( [self.facilitiesPopoverController isPopoverVisible] )
    {
        [self presentFacilitiesPopoverAtIndexPath:self.editingIndexPath];
    }
}

- (void)presentFacilitiesPopoverAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect aFrame = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
    [self.facilitiesPopoverController presentPopoverFromRect:[self.tableView convertRect:aFrame toView:self.view]
                                                      inView:self.view
                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                    animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.view endEditing:YES];
}

- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view
{
    [self presentFacilitiesPopoverAtIndexPath:self.editingIndexPath];
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if( self.isKeyboardUp )
    {
        return YES;
    }
    
    return NO;
}

- (void)doneEditing
{
    [self dismissKeyboard];
    
    if( self.facilitiesPopoverController != nil )
    {
        [self.facilitiesPopoverController dismissPopoverAnimated:YES];
    }
}

#pragma mark - keyboard related

- (void)keyboardWillShow:(NSNotification *)notification
{
    if( self.editingTextView == nil )
    {
        return;
    }
    
    NSValue *keyboard = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [self.view convertRect:[keyboard CGRectValue] fromView:nil];
    CGSize keyboardSize = keyboardRect.size;
    
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = keyboardSize.height;
    
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = keyboardSize.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.contentInset = contentInset;
        self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
    
    if( [self adjustedFieldRow:self.editingIndexPath.row] == MITFacilitiesFormFieldDescription )
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.editingIndexPath.row inSection:0]
                              atScrollPosition:UITableViewRowAnimationTop animated:YES];
    }
    
    self.isKeyboardUp = YES;
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if( self.editingTextView == nil )
    {
        return;
    }
    
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 0.0f;
    
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom = 0.0f;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.contentInset = contentInset;
        self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
    }];
    
    self.isKeyboardUp = NO;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - textViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    CGPoint point = [textView convertPoint:CGPointZero toView:self.tableView];
    self.editingIndexPath = [self.tableView indexPathForRowAtPoint:point];
    self.editingTextView = textView;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if( self.editingIndexPath.row == MITFacilitiesFormFieldEmail )
    {
        self.reportForm.email = textView.text;
    }
    else if( self.editingIndexPath.row == MITFacilitiesFormFieldLocation || self.editingIndexPath.row == MITFacilitiesFormFieldRoom )
    {
        NSDictionary *notifUserInfo = @{@"customText" : (textView.text == nil ? @"" : textView.text)};
        [[NSNotificationCenter defaultCenter] postNotificationName:MITBuildingServicesLocationCustomTextNotification
                                                            object:self
                                                          userInfo:notifUserInfo];
    }
    else
    {
        self.reportForm.reportDescription = textView.text;
    }
    
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, FLT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
    
    [self.tableView beginUpdates];
    
    // if entered custom location, we need to delete room row.
    if( self.editingIndexPath.row == MITFacilitiesFormFieldLocation && [self.tableView numberOfRowsInSection:0] == kNumberOfFieldsWithRoom )
    {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:MITFacilitiesFormFieldRoom inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView endUpdates];
    
    // validate fields
    [self validateFields];
}

#pragma mark - UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    if( image == nil )
    {
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    NSMutableDictionary *imageProperties = [NSMutableDictionary dictionary];
    
    if( [picker sourceType] == UIImagePickerControllerSourceTypeCamera )
    {
        NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
        if( metadata )
        {
            [imageProperties addEntriesFromDictionary:metadata];
        }
        
        dispatch_queue_t tempQueue = dispatch_queue_create("edu.mit.mobile.facilities.UIImagePickerControllerDelegate", 0);
        dispatch_async(tempQueue, ^(void)
        {
            [image updateMetadata:imageProperties withCompletionHandler:^(NSData *imageData)
            {
                [self attachImage:image withImageData:imageData];
            }];
        });
    }
    else if ([picker sourceType] == UIImagePickerControllerSourceTypePhotoLibrary)
    {
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        if (assetURL)
        {
            ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:assetURL
                          resultBlock:^(ALAsset *asset) {
                              [image updateMetadata:[asset.defaultRepresentation.metadata mutableCopy] withCompletionHandler:^(NSData *imageData) {
                                  [self attachImage:image withImageData:imageData];
                              }];
                          }
                         failureBlock:^(NSError *error) {
                             DDLogWarn(@"Failed to load image metadata: %@", [error localizedDescription]);
                         }];
        }
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)attachImage:(UIImage *)image withImageData:(NSData *)imageData
{
    [[MITBuildingServicesReportForm sharedServiceReport] setReportImage:image];
    [[MITBuildingServicesReportForm sharedServiceReport] setReportImageData:imageData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        [self validateFields];
    });
}

#pragma mark - helpers

- (void)validateFields
{
    BOOL enableSubmit = NO;
    
    if( [self.reportForm isValidForm] )
    {
        enableSubmit = YES;
    }
    
    self.submitButton.enabled = enableSubmit;
}

- (NSInteger)numberOfFormFields
{
    NSInteger numberOfRows = self.reportForm.shouldSetRoom ? kNumberOfFieldsWithRoom : kNumberOfFieldsWithoutRoom;
    
    return numberOfRows;
}
       
       
- (NSInteger)lastRowIndex
{
    return [self numberOfFormFields] - 1;
}

- (NSInteger)adjustedFieldRow:(NSInteger)row
{
    // we're not skipping rows if it's "leased"
    if( [self.reportForm.location.isLeased boolValue] )
    {
        return row;
    }
    
    if( !self.reportForm.shouldSetRoom && row >= MITFacilitiesFormFieldRoom )
    {
        row++;
    }
    
    return row;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

@implementation MITFacilitiesEditableFieldCell

- (void)awakeFromNib
{
    [self.subtitleTextView setFont:[UIFont systemFontOfSize:16]];
    CGSize size = [self.subtitleTextView sizeThatFits:CGSizeMake(self.subtitleTextView.frame.size.width, FLT_MAX)];
    CGRect textViewFrame = self.subtitleTextView.frame;
    textViewFrame.size.height = size.height;
    self.subtitleTextView.frame = textViewFrame;
    
    [self.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [self.titleLabel setTextColor:[UIColor mit_tintColor]];
}

@end

@implementation MITFacilitiesNonEditableFieldCell

- (void)awakeFromNib
{
    [self.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [self.subtitleLabel setFont:[UIFont systemFontOfSize:16]];
    
    self.titleLabel.textColor = [UIColor mit_tintColor];
}

@end

@implementation MITFacilitiesLeasedMessageCell

- (void)awakeFromNib
{
    [self.subtitleLabel setFont:[UIFont systemFontOfSize:14]];
}

@end
