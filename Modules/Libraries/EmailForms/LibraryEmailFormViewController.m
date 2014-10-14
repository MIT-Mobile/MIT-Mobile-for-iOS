#import "LibraryEmailFormViewController.h"

#import "LibrariesModule.h"
#import "LibraryFormElements.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITUIConstants.h"
#import "LibraryMenuElementViewController.h"
#import "ThankYouViewController.h"
#import "LibraryTextElementViewController.h"
#import "ExplanatorySectionLabel.h"
#import "MITLoadingActivityView.h"

#define PADDING 10

const NSInteger kLibraryEmailFormTextField = 0x381;
const NSInteger kLibraryEmailFormTextView = 0x382;

UITableViewCell* createTextInputTableCell(UIView *textInputView, CGFloat padding, NSString *key) {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:key];
    CGSize contentSize = cell.contentView.frame.size;
    CGRect textFieldFrame = CGRectMake(padding, padding, contentSize.width - 2 * padding, contentSize.height - 2 * padding);
    textInputView.frame = textFieldFrame;
    textInputView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textInputView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:textInputView];
    return cell;    
}

@interface LibraryEmailFormViewController ()
@property (nonatomic,copy) NSArray *formGroups;
@property (nonatomic,readonly) NSArray *visibleFormGroups;
@property BOOL identityVerified;

- (void)back:(id)sender;
- (void)submitForm:(NSDictionary *)parameters;
- (void)submitForm;
- (BOOL)formValid;

@end

@implementation LibraryEmailFormViewController
@dynamic visibleFormGroups;

- (id)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup the form and event listeners required
    self.tableView.backgroundView = nil;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Submit"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(submitForm)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.prevNextSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Previous", @"Next"]];
    self.prevNextSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.prevNextSegmentedControl.momentary = YES;
    [self.prevNextSegmentedControl addTarget:self
                                      action:@selector(updateFocusedTextView:)
                            forControlEvents:UIControlEventValueChanged];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)];
    
    UIToolbar *inputAccessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    inputAccessoryToolbar.barStyle = UIBarStyleBlack;
    inputAccessoryToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    inputAccessoryToolbar.items = @[[[UIBarButtonItem alloc] initWithCustomView:self.prevNextSegmentedControl],
                                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                    self.doneButton];
    
    _formInputAccessoryView = inputAccessoryToolbar;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextInputView:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextInputView:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSubmitButton:) name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSubmitButton:) name:UITextViewTextDidChangeNotification object:nil];
    
    // force the user to login
    MITLoadingActivityView *loginLoadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
    loginLoadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView addSubview:loginLoadingView];

    NSURLRequest *request = [NSURLRequest requestForModule:LibrariesTag command:@"getUserIdentity" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibraryEmailFormViewController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *content, NSString *contentType, NSError *error) {
        LibraryEmailFormViewController *blockSelf = weakSelf;
        [blockSelf.loadingView removeFromSuperview];

        if (!blockSelf) {
            return;
        } else if (error) {
            if ((error.code == NSURLErrorUserAuthenticationRequired) || (error.code == NSURLErrorUserCancelledAuthentication)) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                DDLogVerbose(@"Request failed with error: %@",[error localizedDescription]);
                [UIAlertView alertViewForError:nil withTitle:@"Login" alertViewDelegate:self];
            }
        } else if (![content isKindOfClass:[NSDictionary class]]) {
            return;
        } else {
            NSNumber *isMITIdentity = content[@"is_mit_identity"];
            if ([isMITIdentity boolValue]) {
                [loginLoadingView removeFromSuperview];
                self.identityVerified = YES;
                [self.tableView reloadData];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not Authorized" message:@"Must login with an MIT account" delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
                [alertView show];
            }
        }
    };
    
    LibrariesModule *librariesModule = (LibrariesModule *)[[MIT_MobileAppDelegate applicationDelegate] moduleWithTag:LibrariesTag];
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:requestOperation];
}

- (NSArray *)visibleFormGroups {
    return [self.formGroups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.hidden = NO"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(back:)];
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray *)textInputs {
    NSMutableArray *textInputs = [NSMutableArray array];
    for (LibraryFormElementGroup *formGroup in self.visibleFormGroups) {
        [textInputs addObjectsFromArray:[formGroup textInputViews]];
    }
    return textInputs;
}

- (NSIndexPath *)indexPathForTextInput:(UIView *)textInput {
    __block NSIndexPath *indexPath = nil;
    
    [self.visibleFormGroups enumerateObjectsUsingBlock:^(LibraryFormElementGroup *group, NSUInteger section, BOOL *stop) {
        [[group elements] enumerateObjectsUsingBlock:^(LibraryFormElement *element, NSUInteger row, BOOL *stop) {
            if ([element textInputView] == textInput) {
                indexPath = [NSIndexPath indexPathForRow:row
                                               inSection:section];
                (*stop) = YES;
            }
        }];
        
        (*stop) = (indexPath != nil);
    }];
    
    return indexPath;
}
  
- (void)updateSubmitButton:(NSNotification *)note {
    if ([note.object respondsToSelector:@selector(tag)]) {
        UIView *changedView = (UIView *)note.object;

        // Only do this if the changed view belongs to this controller.
        // It's possible that another view pushed on top of this is sending 
        // this notification, so it's important to check.
        if (([changedView tag] == kLibraryEmailFormTextField) ||
            ([changedView tag] == kLibraryEmailFormTextView))
        {
            BOOL formValid = [self formValid];
            self.navigationItem.rightBarButtonItem.enabled = [self formValid];
            UIView *lastTextInput = [[self textInputs] lastObject];
            if ([lastTextInput isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)lastTextInput;
                if (formValid) {
                    textField.returnKeyType = UIReturnKeySend;
                } else {
                    textField.returnKeyType = UIReturnKeyDone;
                }
            }
        }
    }
}

- (void)hideKeyboard {
    [self.currentTextView resignFirstResponder];
}

- (void)updateFocusedTextView:(id)sender {
    NSArray *textInputs = [self textInputs];
    NSInteger textInputIndex = [textInputs indexOfObject:self.currentTextView];
    
    UIView *nextTextInput = nil;
    UISegmentedControl *segmentedControl = sender;
    if (segmentedControl.selectedSegmentIndex == 0 && textInputIndex > 0) { // previous button
        nextTextInput = textInputs[textInputIndex - 1];
    } else if (segmentedControl.selectedSegmentIndex == 1 && textInputIndex < [textInputs count]) {
        nextTextInput = textInputs[textInputIndex + 1];
    }

    [nextTextInput becomeFirstResponder];
    [self.tableView scrollToRowAtIndexPath:[self indexPathForTextInput:nextTextInput] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        NSArray *textInputs = [self textInputs];
        NSInteger textInputIndex = [textInputs indexOfObject:self.currentTextView];
        UIView *nextTextInput = textInputs[textInputIndex + 1];
        [nextTextInput becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[self indexPathForTextInput:nextTextInput] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
        if ([self formValid] && textField.returnKeyType == UIReturnKeySend) {
            [self submitForm];
        } else {
            [textField resignFirstResponder];
        }
    }
    return NO;
}

- (void)updateTextInputView:(NSNotification *)notification {
    if ([notification.object respondsToSelector:@selector(tag)])
    {
        UIView *changedView = (UIView *)notification.object;
        
        // Only do this if the changed view belongs to this controller.
        // It's possible that another view pushed on top of this is sending 
        // this notification, so it's important to check.
        if (([changedView tag] == kLibraryEmailFormTextField) ||
            ([changedView tag] == kLibraryEmailFormTextView))
        {
            self.currentTextView = [notification object];
            
            NSArray *textInputs = [self textInputs];
            NSInteger textInputIndex = [textInputs indexOfObject:self.currentTextView];
            BOOL previousEnabled = (textInputIndex != 0);
            BOOL nextEnabled = (textInputIndex !=  (textInputs.count - 1));
            [self.prevNextSegmentedControl setEnabled:previousEnabled forSegmentAtIndex:0];
            [self.prevNextSegmentedControl setEnabled:nextEnabled forSegmentAtIndex:1];
            
            if ([self.currentTextView isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)self.currentTextView;
                if (nextEnabled) {
                    textField.returnKeyType = UIReturnKeyNext;
                } else {
                    if ([self formValid]) {
                        textField.returnKeyType = UIReturnKeySend;
                    } else {
                        textField.returnKeyType = UIReturnKeyDone;
                    }
                }
            }
        }
    }
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    self.loadingView = nil;
    _formInputAccessoryView = nil;
    [self setFormGroups:nil];
    self.currentTextView = nil;
}

- (void)dealloc {
    self.loadingView = nil;
    [self setFormGroups:nil];
    _formInputAccessoryView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    self.currentTextView = nil;
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

- (void)setFormGroups:(NSArray *)formGroups {
    [_formGroups enumerateObjectsUsingBlock:^(LibraryFormElementGroup *formGroup, NSUInteger idx, BOOL *stop) {
        formGroup.formViewController = nil;
    }];
    
    [formGroups enumerateObjectsUsingBlock:^(LibraryFormElementGroup *formGroup, NSUInteger idx, BOOL *stop) {
        formGroup.formViewController = self;
    }];
    
    _formGroups = [formGroups copy];
}

- (NSString *)command {
    return nil;
}

- (NSDictionary *)parameters:(NSDictionary *)parameters {
    return nil;
}

#pragma mark - UITableView data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryFormElementGroup *formGroup = self.visibleFormGroups[indexPath.section];
    NSString *key = [formGroup keyForRow:indexPath.row];
    
    LibraryFormElement *formElement = [formGroup formElementForKey:key];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:key];
    if (!cell) {
        cell = [formElement tableViewCell];
    }
    
    [formElement updateCell:cell];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryFormElementGroup *formGroup = self.visibleFormGroups[indexPath.section];
    NSString *key = [formGroup keyForRow:indexPath.row];
    LibraryFormElement *formElement = [formGroup formElementForKey:key];
    return [formElement heightForTableViewCell];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.visibleFormGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LibraryFormElementGroup *formGroup = self.visibleFormGroups[section];
    return [formGroup numberOfRows];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *formGroupElements = [self.visibleFormGroups[indexPath.section] elements];
    LibraryFormElement *element = formGroupElements[indexPath.row];
    
    if ([element isKindOfClass:[MenuLibraryFormElement class]]) {
        LibraryMenuElementViewController *vc = [[LibraryMenuElementViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.menuElement = (MenuLibraryFormElement *)element;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([element isKindOfClass:[DedicatedViewTextLibraryFormElement class]]) {
        LibraryTextElementViewController *vc = [[LibraryTextElementViewController alloc] init];
        vc.textElement = (DedicatedViewTextLibraryFormElement *)element;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([element isKindOfClass:[ExternalLinkLibraryFormElement class]]) {
        ExternalLinkLibraryFormElement *externalLink = (ExternalLinkLibraryFormElement *)element;
        if ([[UIApplication sharedApplication] canOpenURL:externalLink.url]) {
            [[UIApplication sharedApplication] openURL:externalLink.url];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.identityVerified) {
        LibraryFormElementGroup *formGroup = self.visibleFormGroups[section];
        return formGroup.name;
    }
    return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    LibraryFormElementGroup *formGroup = self.visibleFormGroups[section];
    if (formGroup.footerText) {
        CGFloat height = [ExplanatorySectionLabel heightWithText:formGroup.footerText
                                                           width:CGRectGetWidth(tableView.bounds)
                                                            type:ExplanatorySectionFooter];
        return height;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (self.identityVerified) {
        LibraryFormElementGroup *formGroup = self.visibleFormGroups[section];
        if (formGroup.footerText) {
            ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
            footerLabel.text = formGroup.footerText;
            return footerLabel;
        }
    }

    return nil;
}


- (BOOL)formValid {
    for (LibraryFormElementGroup *formGroup in self.visibleFormGroups) {
        for (NSString *key in [formGroup keys]) {
            NSString *value = [formGroup getFormValueForKey:key];
            
            if ([formGroup valueRequiredForKey:key]) {
                if ([value length] <= 0) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (NSDictionary *)formValues {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (LibraryFormElementGroup *formGroup in self.visibleFormGroups) {
        for (NSString *key in [formGroup keys]) {
            NSString *value = [formGroup getFormValueForKey:key];
            if (value) {
                params[key] = value;
            }
        }
    }
    return params;
}

- (void)submitForm {
    [self.currentTextView resignFirstResponder];
    [self submitForm:[self formValues]];
}

- (void)showErrorSubmittingForm {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Error submitting form"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (void)submitForm:(NSDictionary *)parameters {
    LibrariesModule *librariesModule = (LibrariesModule *)[[MIT_MobileAppDelegate applicationDelegate] moduleWithTag:LibrariesTag];

    ThankYouViewController *thanksController = [[ThankYouViewController alloc] initWithMessage:nil];
    thanksController.title = @"Submitting";
    [self.navigationController pushViewController:thanksController animated:YES];


    NSURLRequest *request = [NSURLRequest requestForModule:LibrariesTag command:[self command] parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibraryEmailFormViewController *weakSelf = self;
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *content, NSString *contentType, NSError *error) {
        LibraryEmailFormViewController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogVerbose(@"Request failed with error: %@",[error localizedDescription]);
            [self.navigationController popViewControllerAnimated:NO];
            [self showErrorSubmittingForm];
        } else if (![content isKindOfClass:[NSDictionary class]]) {
            [self.navigationController popViewControllerAnimated:NO];
            [self showErrorSubmittingForm];
        } else {
            BOOL success = [content[@"success"] boolValue];
            if (!success) {
                DDLogVerbose(@"server reported an error for request v2:%@/%@",operation.module,operation.command);
                [self.navigationController popViewControllerAnimated:NO];
                [self showErrorSubmittingForm];
            } else {
                NSDictionary *resultsDict = content[@"results"];
                NSString *text = [NSString stringWithFormat:@"%@\n\nYou will be contacted at %@.",resultsDict[@"thank_you_text"],resultsDict[@"email"]];

                thanksController.title = @"Thank You";
                thanksController.message = text;
            }
        }
    };

    [librariesModule.requestQueue addOperation:requestOperation];
}

- (LibraryFormElementGroup *)groupForName:(NSString *)name {
    for (LibraryFormElementGroup *formGroup in self.formGroups) {
        if ([formGroup.name isEqualToString:name]) {
            return formGroup;
        }
    }
    return nil;
}

- (LibraryFormElement *)statusMenuFormElementWithRequired:(BOOL)required {
    return [[MenuLibraryFormElement alloc] initWithKey:@"status"
                                          displayLabel:@"Status"
                                              required:required
                                                values:@[@"UG",
                                                         @"GRAD",
                                                         @"FAC",
                                                         @"RS",
                                                         @"STAFF",
                                                         @"VS"]
                                         displayValues:@[@"MIT Undergrad Student",
                                                         @"MIT Grad Student",
                                                         @"MIT Faculty",
                                                         @"MIT Research Staff",
                                                         @"MIT Staff",
                                                         @"MIT Visitor"]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // network error message being dismmised
    [self.navigationController popViewControllerAnimated:YES];
}
@end
