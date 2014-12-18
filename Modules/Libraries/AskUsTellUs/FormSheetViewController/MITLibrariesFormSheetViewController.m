#import "MITLibrariesFormSheetViewController.h"
#import "MITLibrariesFormSheetCellOptions.h"
#import "MITLibrariesFormSheetCellSingleLineTextEntry.h"
#import "MITLibrariesFormSheetCellMultiLineTextEntry.h"
#import "MITLibrariesFormSheetCellWebLink.h"
#import "UIKit+MITAdditions.h"
#import "MITTouchstoneController.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesMITIdentity.h"

static NSString * const MITLibrariesFormSheetCellIdentifierOptions = @"MITLibrariesFormSheetCellIdentifierOptions";
static NSString * const MITLibrariesFormSheetCellIdentifierSingleLineTextEntry = @"MITLibrariesFormSheetCellIdentifierSingleLineTextEntry";
static NSString * const MITLibrariesFormSheetCellIdentifierMultiLineTextEntry = @"MITLibrariesFormSheetCellIdentifierMultiLineTextEntry";
static NSString * const MITLibrariesFormSheetCellIdentifierWebLink = @"MITLibrariesFormSheetCellIdentifierWebLink";

static NSString * const MITLibrariesFormSheetViewControllerNibName = @"MITLibrariesFormSheetViewController";

@interface MITLibrariesFormSheetViewController () <UITableViewDataSource, UITableViewDelegate, MITLibrariesFormSheetTextEntryCellDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation MITLibrariesFormSheetViewController

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:MITLibrariesFormSheetViewControllerNibName bundle:nil];
    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self verifyAuthorization];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerKeyboardListeners];
    [self reloadTableView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unregisterKeyboardListeners];
}

#pragma mark - Setup

- (void)setup
{
    [self setupTableView];
    [self setupNavigationBar];
}

- (void)setupTableView
{
    self.tableView.hidden = NO;
    [self registerTableViewCells];
}

- (void)registerTableViewCells
{
    UINib *optionsCellNib = [UINib nibWithNibName:MITLibrariesFormSheetCellOptionsNibName bundle:nil];
    [self.tableView registerNib:optionsCellNib forCellReuseIdentifier:MITLibrariesFormSheetCellIdentifierOptions];
    
    UINib *singleLineEntryCellNib = [UINib nibWithNibName:MITLibrariesFormSheetCellSingleLineTextEntryNibName bundle:nil];
    [self.tableView registerNib:singleLineEntryCellNib forCellReuseIdentifier:MITLibrariesFormSheetCellIdentifierSingleLineTextEntry];
    
    UINib *multiLineEntryCellNib = [UINib nibWithNibName:MITLibrariesFormSheetCellMultiLineTextEntryNibName bundle:nil];
    [self.tableView registerNib:multiLineEntryCellNib forCellReuseIdentifier:MITLibrariesFormSheetCellIdentifierMultiLineTextEntry];
    
    UINib *webLinkCellNib = [UINib nibWithNibName:MITLibrariesFormSheetCellWebLinkNibName bundle:nil];
    [self.tableView registerNib:webLinkCellNib forCellReuseIdentifier:MITLibrariesFormSheetCellIdentifierWebLink];
}

- (void)setupNavigationBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(submitButtonPressed:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - Keyboard Functionality

- (void)registerKeyboardListeners
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)unregisterKeyboardListeners
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary *keyboardAnimationDetail = note.userInfo;
    UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect keyboardFrame = [keyboardAnimationDetail[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? CGRectGetHeight(keyboardFrame) : CGRectGetWidth(keyboardFrame);
    
    CGRect rectInWindow = [self.view convertRect:self.view.bounds toView:[UIApplication sharedApplication].keyWindow];
    CGFloat totalWindowHeight =  CGRectGetHeight([UIApplication sharedApplication].keyWindow.bounds);
    CGFloat maxFormSheetY = CGRectGetMaxY(rectInWindow);
    CGFloat keyboardAdjustmentOffset = totalWindowHeight - maxFormSheetY;
    
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
        UIEdgeInsets contentInsets = self.tableView.contentInset;
        contentInsets.bottom = keyboardHeight - keyboardAdjustmentOffset;
        self.tableView.contentInset = contentInsets;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary *keyboardAnimationDetail = note.userInfo;
    UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
        UIEdgeInsets contentInsets = self.tableView.contentInset;
        contentInsets.bottom = 0;
        self.tableView.contentInset = contentInsets;
    } completion:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)note
{
    NSDictionary *keyboardAnimationDetail = note.userInfo;
    UIViewAnimationCurve animationCurve = [keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect keyboardFrame = [keyboardAnimationDetail[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? CGRectGetHeight(keyboardFrame) : CGRectGetWidth(keyboardFrame);
    
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
        UIEdgeInsets currentInsets = self.tableView.contentInset;
        currentInsets.bottom = keyboardHeight;
        self.tableView.contentInset = currentInsets;
    } completion:nil];
}

#pragma mark - Authorization

- (void)verifyAuthorization
{
    self.tableView.hidden = YES;
    if (![[MITTouchstoneController sharedController] isLoggedIn]) {
        [self showActivityIndicator];
        [[MITTouchstoneController sharedController] login:^(BOOL success, NSError *error) {
            [self hideActivityIndicator];
            if (error || !success) {
                NSLog(@"Login Failed w/ Error: %@", error);
                [self closeFormSheetViewController];
            } else {
                [self verifyMITIdentity];
            }
        }];
    } else {
        [self verifyMITIdentity];
    }
}

- (void)verifyMITIdentity
{
    [self showActivityIndicator];
    [MITLibrariesWebservices getMITIdentityInBackgroundWithCompletion:^(MITLibrariesMITIdentity *identity, NSError *error) {
        [self hideActivityIndicator];
        if (error || !identity) {
            [self showUnableToRetrieveMITIdentityAlert];
        } else if (identity.isMITIdentity) {
            [self setup];
        } else {
            [self showMITIdentityRequiredAlert];
        }
    }];
}

- (void)showUnableToRetrieveMITIdentityAlert
{
    NSString *title = @"Network Failure";
    NSString *message = @"We were unable to fetch your MIT identity from the network.  Please check your connection and try again in a little bit.";
    NSString *confirmation = @"Ok";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:confirmation, nil];
    [alert show];
}

- (void)showMITIdentityRequiredAlert
{
    NSString *title = @"MIT Identity Required";
    NSString *message = @"This action requires a verified MIT identity to continue.";
    NSString *confirmation = @"Ok";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:confirmation, nil];
    [alert show];
}

#pragma mark - Closing FormSheet View Controller

- (void)closeFormSheetViewController
{
    if (self.navigationController) {
        if (self.navigationController.presentingViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Activity Indicator

- (void)showActivityIndicator
{
    [self.activityIndicator startAnimating];
}

- (void)hideActivityIndicator
{
    [self.activityIndicator stopAnimating];
}

#pragma mark - Button Presses

- (void)submitButtonPressed:(UIBarButtonItem *)sender
{
    [self submitFormForParameters:[MITLibrariesWebservices formSheetGroupsAsHTMLParametersDictionary:self.formSheetGroups]];
}

#pragma mark - Form Submission

- (void)submitFormForParameters:(NSDictionary *)parameters
{
    NSLog(@"FORM SHEET VIEW CONTROLLER: Should be implemented by subclass");
}

#pragma mark - Form Submission Error / Success Notifications

- (void)notifyFormSubmissionError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Submit Form!"
                                                    message:@"Please verify that you have a valid internet connection and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

- (void)notifyFormSubmissionSuccessWithResponseObject:(id)responseObject
{
    NSString *message;
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSString *thankYou = responseObject[@"thank_you_text"];
        NSString *email = responseObject[@"email"];
        if (thankYou) {
            message = thankYou;
        }
        if (thankYou && email) {
            message = [NSString stringWithFormat:@"%@\n\nYou will be contacted at %@.", thankYou, email];
        } else if (thankYou) {
            message = thankYou;
        } else if (email) {
            message = [NSString stringWithFormat:@"Thanks for your submission! You will be contacted at %@", email];
        } else {
            message = [NSString stringWithFormat:@"Thank you for your submission!"];
        }
    }
    
    NSString *title = @"Submitted";
    NSString *confirmation = @"OK";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:confirmation, nil];
    [alert show];
}

#pragma mark - Submit Button Validation

- (void)updateSubmitButton
{
    self.navigationItem.rightBarButtonItem.enabled = [self isFormValid];
}

#pragma mark - Form Validity

- (BOOL)isFormValid
{
    BOOL isFormValid = YES;
    
    for (MITLibrariesFormSheetGroup *group in self.formSheetGroups) {
        for (MITLibrariesFormSheetElement *element in group.elements) {
            if (!element.optional && !element.value) {
                isFormValid = NO;
                break;
            }
        }
        if (!isFormValid) {
            break;
        }
    }
    
    return isFormValid;
}

#pragma mark - TableView Reload

- (void)reloadTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.formSheetGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[section];
    return groupForSection.elements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[indexPath.section];
    MITLibrariesFormSheetElement *elementForRow = groupForSection.elements[indexPath.row];
    
    UITableViewCell<MITLibrariesFormSheetCellProtocol> *cell;
    switch (elementForRow.type) {
        case MITLibrariesFormSheetElementTypeOptions:
            cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesFormSheetCellIdentifierOptions forIndexPath:indexPath];
            break;
        case MITLibrariesFormSheetElementTypeSingleLineTextEntry:
            cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesFormSheetCellIdentifierSingleLineTextEntry forIndexPath:indexPath];
            [(UITableViewCell<MITLibrariesFormSheetTextEntryCellProtocol> *)cell setDelegate:self];
            break;
        case MITLibrariesFormSheetElementTypeMultiLineTextEntry:
            cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesFormSheetCellIdentifierMultiLineTextEntry forIndexPath:indexPath];
            [(UITableViewCell<MITLibrariesFormSheetTextEntryCellProtocol> *)cell setDelegate:self];
            break;
        case MITLibrariesFormSheetElementTypeWebLink:
            cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesFormSheetCellIdentifierWebLink forIndexPath:indexPath];
            break;
    }
    
    [cell configureCellForFormSheetElement:elementForRow];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[section];
    return groupForSection.headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[section];
    return groupForSection.footerTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[indexPath.section];
    MITLibrariesFormSheetElement *elementForRow = groupForSection.elements[indexPath.row];
    
    CGFloat height;
    switch (elementForRow.type) {
        case MITLibrariesFormSheetElementTypeOptions:
            height = [MITLibrariesFormSheetCellOptions heightForCell];
            break;
        case MITLibrariesFormSheetElementTypeSingleLineTextEntry:
            height = [MITLibrariesFormSheetCellSingleLineTextEntry heightForCell];
            break;
        case MITLibrariesFormSheetElementTypeMultiLineTextEntry:
            height = [MITLibrariesFormSheetCellMultiLineTextEntry heightForCell];
            break;
        case MITLibrariesFormSheetElementTypeWebLink:
            height = [MITLibrariesFormSheetCellWebLink heightForCell];
            break;
    }
    return height;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[indexPath.section];
    MITLibrariesFormSheetElement *elementForRow = groupForSection.elements[indexPath.row];
    
    switch (elementForRow.type) {
        case MITLibrariesFormSheetElementTypeOptions: {
            MITLibrariesFormSheetOptionsSelectionViewController *optionsSelectorVC = [MITLibrariesFormSheetOptionsSelectionViewController new];
            optionsSelectorVC.element = elementForRow;
            [self.navigationController pushViewController:optionsSelectorVC animated:YES];
            break;
        }
        case MITLibrariesFormSheetElementTypeWebLink: {
            NSURL *url = [NSURL URLWithString:elementForRow.value];
            if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        }
        case MITLibrariesFormSheetElementTypeSingleLineTextEntry:
        case MITLibrariesFormSheetElementTypeMultiLineTextEntry: {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if ([cell conformsToProtocol:@protocol(MITLibrariesFormSheetTextEntryCellProtocol)]) {
                [(UITableViewCell<MITLibrariesFormSheetTextEntryCellProtocol> *)cell makeTextEntryFirstResponder];
            }
        }
    }
}

#pragma mark - MITLibrariesFormSheetTextEntryCellDelegate

- (void)textEntryCell:(UITableViewCell<MITLibrariesFormSheetTextEntryCellProtocol> *)cell didUpdateValue:(id)value
{
    NSIndexPath *indexPathForCell = [self.tableView indexPathForCell:cell];
    if (indexPathForCell) {
        MITLibrariesFormSheetGroup *groupForSection = self.formSheetGroups[indexPathForCell.section];
        MITLibrariesFormSheetElement *elementForRow = groupForSection.elements[indexPathForCell.row];
        elementForRow.value = value;
        [self updateSubmitButton];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self closeFormSheetViewController];
}

@end
