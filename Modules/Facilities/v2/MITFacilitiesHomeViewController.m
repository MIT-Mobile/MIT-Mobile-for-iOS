//
//  MITFacilitiesHomeViewController.m
//  MIT Mobile
//
//  Created by Yev Motov on 9/1/14.
//
//

#import "MITFacilitiesHomeViewController.h"
#import "MITBuildingServicesReportForm.h"
#import "MITTouchstoneController.h"
#import "MITActionSheetHandler.h"

#import "FacilitiesCategoryViewController.h"
#import "FacilitiesTypeViewController.h"
#import "FacilitiesRoomViewController.h"

#import "UIKit+MITAdditions.h"
#import <MessageUI/MFMailComposeViewController.h>

typedef NS_ENUM(NSUInteger, MITFacilitiesFormFieldType) {
    MITFacilitiesFormFieldEmail = 0,
    MITFacilitiesFormFieldLocation,
    MITFacilitiesFormFieldRoom,
    MITFacilitiesFormFieldProblemType,
    MITFacilitiesFormFieldDescription,
    MITFacilitiesFormFieldAttachPhoto
};

static NSString* const kFacilitiesEmailAddress = @"txtdof@mit.edu";
static NSString* const kFacilitiesPhoneNumber = @"(617) 253-4948";

@interface MITFacilitiesHomeViewController () <UITableViewDataSource, UITextViewDelegate, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *contactFacilitiesButton;

@property (nonatomic, strong) MITBuildingServicesReportForm *reportForm;

@property (nonatomic, strong) UITextView *editingTextView;
@property (nonatomic, assign) NSInteger editingRow;

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
    // Do any additional setup after loading the view.
    
    self.reportForm = [MITBuildingServicesReportForm sharedServiceReport];
    [self.reportForm clearAll];
    
    self.editingTextView = nil;
    self.editingRow = -1;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.contactFacilitiesButton addTarget:self action:@selector(contactFacilitiesAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
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
        
        if( buttonIndex == actionSheet.destructiveButtonIndex )
        {
            // call
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://1%@",kFacilitiesPhoneNumber]];
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                [[UIApplication sharedApplication] openURL:url];
            }
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
                                               destructiveButtonTitle:[NSString stringWithFormat:@"Call %@", kFacilitiesPhoneNumber]
                                                    otherButtonTitles:[NSString stringWithFormat:@"Email %@", kFacilitiesEmailAddress], nil];
    [actionSheet showInView:self.view];
}

- (void)attachPhotoAction
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
        
        if( buttonIndex == actionSheet.destructiveButtonIndex )
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
                                               destructiveButtonTitle:@"Take Photo"
                                                    otherButtonTitles:@"Choose Photo", nil];
    [actionSheet showInView:self.view];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - tableview stuff

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSInteger defaultHeight = 62;
    
    NSInteger row = [self adjustedFieldRow:indexPath.row];
    
    if( self.editingTextView != nil && row == self.editingRow && row != MITFacilitiesFormFieldEmail )
    {
        CGSize size = [self.editingTextView sizeThatFits:CGSizeMake(self.editingTextView.frame.size.width, FLT_MAX)];
        
        return (defaultHeight - 20) + size.height;
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
    
    if( indexPath.row == [self lastRowIndex] )
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
    
    UILabel *actionLabel = (UILabel *)[cell viewWithTag:1];
    [actionLabel setText:@"Attach Photo"];
    [actionLabel setTextColor:[UIColor mit_tintColor]];
    
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 1000.);
    
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
    
    cell.separatorInset = UIEdgeInsetsMake(0, 7., 0, 0);
    
    return cell;
}

- (MITFacilitiesEditableFieldCell *)emailFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeEditableCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.titleLabel.text = @"email";
    cell.subtitleTextView.text = [[MITTouchstoneController sharedController] userEmailAddress];
    cell.subtitleTextView.delegate = self;
    
    return cell;
}

- (MITFacilitiesNonEditableFieldCell *)locationFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.titleLabel.text = @"location";
    cell.subtitleLabel.text = self.reportForm.location.name;
    
    return cell;
}

- (MITFacilitiesNonEditableFieldCell *)roomFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.titleLabel.text = @"room";
    cell.subtitleLabel.text = self.reportForm.room == nil ? self.reportForm.roomAltName : self.reportForm.room.number;
    
    return cell;
}

- (MITFacilitiesNonEditableFieldCell *)problemTypeFieldCellWithIndexPath:(NSIndexPath *)indexPath
{
    MITFacilitiesNonEditableFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AttributeNonEditableCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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
    cell.subtitleTextView.text = self.reportForm.description;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *vc = nil;
    
    NSInteger row = [self adjustedFieldRow:indexPath.row];
    
    if( row == MITFacilitiesFormFieldAttachPhoto )
    {
        [self attachPhotoAction];
        return;
    }
    
    if( row == MITFacilitiesFormFieldLocation )
    {
        vc = [[FacilitiesCategoryViewController alloc] init];
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
    }
    
    if( vc != nil )
    {
        [self.navigationController pushViewController:vc animated:YES];
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
    
    CGRect tableViewRect = self.tableView.frame;
    tableViewRect.size.height -= keyboardSize.height;
    self.tableView.frame = tableViewRect;
    
    if( self.editingRow == MITFacilitiesFormFieldDescription )
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.editingRow inSection:0]
                              atScrollPosition:UITableViewRowAnimationTop animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if( self.editingTextView == nil )
    {
        return;
    }
    
    NSValue *keyboardValue = [[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [keyboardValue CGRectValue];
    CGSize keyboardSize = keyboardRect.size;
    
    CGRect tableViewRect = self.tableView.frame;
    tableViewRect.size.height += keyboardSize.height;
    self.tableView.frame = tableViewRect;
}

#pragma mark - textViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    CGPoint point = [textView convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *editingTextViewIndexPath = [self.tableView indexPathForRowAtPoint:point];
    
    self.editingRow = [self adjustedFieldRow:editingTextViewIndexPath.row];
    self.editingTextView = textView;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.reportForm.description = textView.text;
    
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, FLT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    if( image == nil )
    {
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - helpers

- (NSInteger)numberOfFormFields
{
    NSInteger numberOfRows = self.reportForm.shouldSetRoom ? 6 : 5;
    
    return numberOfRows;
}
       
       
- (NSInteger)lastRowIndex
{
    return [self numberOfFormFields] - 1;
}

- (NSInteger)adjustedFieldRow:(NSInteger)row
{
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
