#import "LibraryEmailFormViewController.h"
#import "LibrariesModule.h"
#import "MobileRequestOperation.h"
#import "MITUIConstants.h"
#import "LibraryMenuElementViewController.h"
#import "ThankYouViewController.h"
#import "LibraryTextElementViewController.h"
#import "ExplanatorySectionLabel.h"

#define PADDING 10

static const NSInteger kLibraryEmailFormTextField = 0x381;
static const NSInteger kLibraryEmailFormTextView = 0x382;

@implementation LibraryFormElement
@synthesize key;
@synthesize displayLabel;
@synthesize displayLabelSubtitle;
@synthesize required;
@synthesize delegate;
@synthesize formViewController;

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel displayLabelSubtitle:(NSString *)aDisplayLabelSubtitle required:(BOOL)isRequired {
    self = [super init];
    if (self) {
        self.key = aKey;
        self.displayLabel = aDisplayLabel;
        self.displayLabelSubtitle = aDisplayLabelSubtitle;
        self.required = isRequired;
        self.formViewController = nil;
    }
    return self;
}
- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired {
    return [self initWithKey:aKey displayLabel:aDisplayLabel displayLabelSubtitle:nil required:isRequired];
}

- (void)dealloc {
    self.key = nil;
    self.displayLabel = nil;
    self.formViewController = nil;
    [super dealloc];
}

- (UITableViewCell *)tableViewCell {
    NSAssert(NO, @"Need to override method tableViewCell");
    return nil;
}

- (void)updateCell:(UITableViewCell *)tableViewCell {
    NSAssert(NO, @"Need to override method updatetCell:");
}

- (CGFloat)heightForTableViewCell {
    NSAssert(NO, @"Need to override method heightForTableViewCell"); 
    return 0;
}

- (UIView *)textInputView {
    NSAssert(NO, @"Need to override method textInputView");
    return nil;
}

- (NSString *)value {
    NSAssert(NO, @"Need to override method value");
    return nil;
}

@end

@implementation MenuLibraryFormElement
@synthesize options;
@synthesize displayOptions;
@dynamic value;

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues displayValues:(NSArray *)theDisplayValues {
    self = [super initWithKey:aKey displayLabel:aDisplayLabel required:isRequired];
    if (self) {
        self.options = theValues;
        self.displayOptions = theDisplayValues;
        self.currentOptionIndex = 0;
    }
    return self;
}


- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues {
    return [self initWithKey:aKey displayLabel:aDisplayLabel required:isRequired values:theValues displayValues:theValues];
}

- (void)dealloc {
    self.options = nil;
    self.displayOptions = nil;
    [super dealloc];
}


- (void)updateCell:(UITableViewCell *)tableViewCell {
    tableViewCell.detailTextLabel.text = [self.displayOptions objectAtIndex:self.currentOptionIndex];
}

- (UITableViewCell *)tableViewCell {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.key] autorelease];
    cell.textLabel.text = self.displayLabel;
    cell.detailTextLabel.text = [self.displayOptions objectAtIndex:self.currentOptionIndex];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 50;
}

- (UIView *)textInputView {
    return nil;
}

- (void)setCurrentOptionIndex:(NSInteger)currentOptionIndex {
    if (currentOptionIndex != _currentOptionIndex) {
        _currentOptionIndex = currentOptionIndex;
        [self.delegate valueChangedForElement:self];
    }
}

- (NSInteger)currentOptionIndex {
    return _currentOptionIndex;
}

- (NSString *)value {
    return [self.options objectAtIndex:self.currentOptionIndex];
}

- (void)setValue:(NSString *)value {
    NSInteger index = [self.options indexOfObject:value];
    if (index == NSNotFound) {
        ELog(@"Unable to set field to \"%@\" as it does not exist among possible options: %@", value, self.options);
    } else {
        self.currentOptionIndex = index;
    }
}

@end

@implementation DedicatedViewTextLibraryFormElement

static const CGFloat kDedicatedViewElementPlaceholderHeight = 44.0f;

- (void)dealloc 
{
    [textValue_ release];
    [super dealloc];
}

- (void)updateCell:(UITableViewCell *)tableViewCell 
{
    tableViewCell.detailTextLabel.text = [self textValue];
}

// This is for the cell in a form table not a LibraryTextElementViewController 
// cell.
- (UITableViewCell *)tableViewCell 
{
    UITableViewCell *cell = 
    [[[UITableViewCell alloc] 
      initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.key] 
     autorelease];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = 
    placeholderText(self.displayLabel, self.required);
    
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return kDedicatedViewElementPlaceholderHeight;
}

- (UIView *)textInputView {
    return nil;
}

- (NSString *)value {
    return self.textValue;
}

- (void)setTextValue:(NSString *)textValue
{   
    [textValue_ release];
    textValue_ = [textValue retain];
}

- (NSString *)textValue
{
    return textValue_;
}

@end


UITableViewCell* createTextInputTableCell(UIView *textInputView, CGFloat padding, NSString *key) {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:key] autorelease];
    CGSize contentSize = cell.contentView.frame.size;
    CGRect textFieldFrame = CGRectMake(padding, padding, contentSize.width - 2*padding, contentSize.height - 2*padding);
    textInputView.frame = textFieldFrame;
    textInputView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textInputView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:textInputView];
    return cell;    
}

NSString* placeholderText(NSString *displayLabel, BOOL required) {
    NSString *placeHolder = displayLabel;
    if (!required) {
        placeHolder = [placeHolder stringByAppendingString:@" (optional)"];
    }
    return placeHolder;
}

@implementation TextLibraryFormElement
@synthesize textField;
@synthesize keyboardType;

- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel 
         required:(BOOL)required {
    self = [super initWithKey:key displayLabel:displayLabel required:required];
    if (self)
    {
        self.keyboardType = UIKeyboardTypeDefault;
    }
    return self;
}

- (void)dealloc {
    self.textField.delegate = nil;
    self.textField = nil;
    [super dealloc];
}

- (void)updateCell:(UITableViewCell *)tableViewCell { }

- (UITableViewCell *)tableViewCell {
    self.textField = (UITextField *)[self textInputView];
    self.textField.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    self.textField.placeholder = placeholderText(self.displayLabel, self.required);
    self.textField.inputAccessoryView = self.formViewController.formInputAccessoryView;
    self.textField.keyboardType = self.keyboardType;
    return createTextInputTableCell(self.textField, 10, self.key);
}

- (CGFloat)heightForTableViewCell {
    return 46;
}

- (UIView *)textInputView {
    if (!self.textField) {
        self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
        self.textField.tag = kLibraryEmailFormTextField;
        self.textField.delegate = self;
    }
    return self.textField;
}

- (NSString *)value {
    return self.textField.text;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    return [self.formViewController textFieldShouldReturn:aTextField];
}

@end

@implementation TextAreaLibraryFormElement
@synthesize textView;

- (void)dealloc {
    self.textView = nil;
    [super dealloc];
}

- (void)updateCell:(UITableViewCell *)tableViewCell { }

- (UITableViewCell *)tableViewCell {
    self.textView = (PlaceholderTextView *)[self textInputView];
    self.textView.placeholder = placeholderText(self.displayLabel, self.required);
    self.textView.inputAccessoryView = self.formViewController.formInputAccessoryView;
    self.textView.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    return createTextInputTableCell(self.textView, 4, self.key);
}

- (CGFloat)heightForTableViewCell {
    return 110;
}

- (UIView *)textInputView {
    if (!self.textView) {
        self.textView = [[[PlaceholderTextView alloc] initWithFrame:CGRectZero] autorelease];
        self.textView.tag = kLibraryEmailFormTextView;
    }
    return self.textView;
}

- (NSString *)value {
    return self.textView.text;
}

@end

@implementation ExternalLinkLibraryFormElement

@synthesize url;

- (void)dealloc {
    self.url = nil;
    [super dealloc];
}

- (UITableViewCell *)tableViewCell {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key] autorelease];
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 46;
}

- (NSString *)value {
    return nil;
}

- (void)updateCell:(UITableViewCell *)tableViewCell {
    tableViewCell.textLabel.text = self.displayLabel;
    tableViewCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
}

- (UIView *)textInputView {
    return nil;
}


@end

@implementation LibraryFormElementGroup
@synthesize name;
@synthesize headerText;
@synthesize footerText;
@synthesize hidden;

+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements {
    return [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
}

+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements {
    LibraryFormElementGroup *group = [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
    group.hidden = YES;
    return group;
}

- (id)initWithName:(NSString *)aName formElements:(NSArray *)theFormElements {
    self = [super init];
    if (self) {
        formElements = [theFormElements retain];
        self.name = aName;
    }
    return self;
}

- (NSArray *)textInputViews {
    NSMutableArray *textInputViews = [NSMutableArray array];
    for (LibraryFormElement *formElement in formElements) {
         if ([formElement textInputView]) {
             [textInputViews addObject:[formElement textInputView]];
        }
    }
    return textInputViews;
}

- (void)dealloc {
    [formElements release];
    self.name = nil;
    [super dealloc];
}
    
- (BOOL)valueRequiredForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement.required;
        }
    }
    
    [NSException raise:@"key not found in form" format:@"%@ not found in group", key];
    return NO;
}

- (NSString *)getFormValueForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return [[formElement value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
        }
    }
    
    [NSException raise:@"key not found in form" format:@"%@ not found in group", key];
    return nil;

}


- (NSArray *)keys {
    NSMutableArray *keys = [NSMutableArray array];
    for(LibraryFormElement *formElement in formElements) {
        [keys addObject:formElement.key];
    }
    return keys;
}

- (NSArray *)elements {
    return formElements;
}

- (NSString *)keyForRow:(NSInteger)row {
    return [[self keys] objectAtIndex:row];
}

- (LibraryFormElement *)formElementForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement;
        }
    }
    return nil;
}


- (NSInteger)numberOfRows {
    return formElements.count;
}

- (void)setFormViewController:(LibraryEmailFormViewController *)aFormViewController {
    if (aFormViewController) {
        for(LibraryFormElement *element in formElements) {
            element.formViewController = aFormViewController;
        }
    }
    _formViewController = aFormViewController;
}

- (LibraryEmailFormViewController *)formViewController {
    return _formViewController;
}

@end

@interface LibraryEmailFormViewController (Private)
- (NSArray *)nonHiddenFormGroups;
- (void)back:(id)sender;
- (void)submitForm:(NSDictionary *)parameters;
- (void)submitForm;
- (BOOL)formValid;

@end

@implementation LibraryEmailFormViewController
@synthesize loadingView;
@synthesize prevNextSegmentedControl;
@synthesize doneButton;
@synthesize formInputAccessoryView;
@synthesize currentTextView;

- (id)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)setFormGroups:(NSArray *)formGroups {
    if (_formGroups) {
        for (LibraryFormElementGroup *formGroup in _formGroups) {
            formGroup.formViewController = nil;
        }
    }
    [_formGroups release];
    _formGroups = [formGroups retain];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];    
    
    
    // setup the form and event listeners required
    self.tableView.backgroundColor = [UIColor clearColor];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Submit" 
                                                                               style:UIBarButtonItemStyleDone 
                                                                              target:self 
                                                                              action:@selector(submitForm)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self setFormGroups:[self formGroups]];
    
    self.prevNextSegmentedControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Previous", @"Next", nil]] autorelease];
    self.prevNextSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.prevNextSegmentedControl.momentary = YES;
    [self.prevNextSegmentedControl addTarget:self action:@selector(updateFocusedTextView:) forControlEvents:UIControlEventValueChanged];
    
    self.doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)] autorelease];
    
    UIToolbar *inputAccessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    inputAccessoryToolbar.barStyle = UIBarStyleBlack;
    inputAccessoryToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    inputAccessoryToolbar.items = [NSArray arrayWithObjects:
                                   [[[UIBarButtonItem alloc] initWithCustomView:self.prevNextSegmentedControl] autorelease],
                                   [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                                   self.doneButton,
                                   nil];
    
    [formInputAccessoryView release];
    formInputAccessoryView = inputAccessoryToolbar;
    
    for (LibraryFormElementGroup *formGroup in _formGroups) {
        formGroup.formViewController = self;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextInputView:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTextInputView:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSubmitButton:) name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSubmitButton:) name:UITextViewTextDidChangeNotification object:nil];
    
    // force the user to login
    MITLoadingActivityView *loginLoadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
    loginLoadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView addSubview:loginLoadingView];
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:LibrariesTag
                                                                              command:@"getUserIdentity"
                                                                           parameters:[NSDictionary dictionary]] autorelease];
    
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        [self.loadingView removeFromSuperview];
        
        if (error && (error.code != NSUserCancelledError)) {
            DLog(@"Request failed with error: %@",[error localizedDescription]); 
            [MITMobileWebAPI showError:nil header:@"Login" alertViewDelegate:self];
        } else if (!jsonResult) {
            [self.navigationController popViewControllerAnimated:YES];    
        } else {
            NSNumber *isMITIdentity = [(NSDictionary *)jsonResult objectForKey:@"is_mit_identity"];
            if ([isMITIdentity boolValue]) {
                [loginLoadingView removeFromSuperview];
                identityVerified = YES;
                [self.tableView reloadData];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Not Authorized" message:@"Must login with an MIT account" delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
                [alertView show];
                [alertView release];
            }
        }
    };
    
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:request];
}

- (NSArray *)nonHiddenFormGroups {
    NSMutableArray *nonHiddenFormGroups = [NSMutableArray array];
    for (LibraryFormElementGroup *formGroup in _formGroups) {
        if (!formGroup.hidden) {
            [nonHiddenFormGroups addObject:formGroup];
        }
    }
    return nonHiddenFormGroups;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(back:)] autorelease];
}

- (void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray *)textInputs {
    NSMutableArray *textInputs = [NSMutableArray array];
    for (LibraryFormElementGroup *formGroup in [self nonHiddenFormGroups]) {
        [textInputs addObjectsFromArray:[formGroup textInputViews]];
    }
    return textInputs;
}

- (NSIndexPath *)indexPathForTextInput:(UIView *)textInput {
    for (int section=0; section < [self nonHiddenFormGroups].count; section++) {
        LibraryFormElementGroup *group = [[self nonHiddenFormGroups] objectAtIndex:section];
        NSArray *elements = [group elements];
        for (int row=0; row < [elements count]; row++) {
            LibraryFormElement *element = [elements objectAtIndex:row];
            if ([element textInputView] == textInput) {
                return [NSIndexPath indexPathForRow:row inSection:section]; 
            }
        }
    }
    return nil;
}
  
- (void)updateSubmitButton:(NSNotification *)note {
    if ([note.object respondsToSelector:@selector(tag)])
    {
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
        nextTextInput = [textInputs objectAtIndex:textInputIndex-1];
    } else if (segmentedControl.selectedSegmentIndex == 1 && textInputIndex < textInputs.count) {
        nextTextInput = [textInputs objectAtIndex:textInputIndex+1];
    }

    [nextTextInput becomeFirstResponder];
    [self.tableView scrollToRowAtIndexPath:[self indexPathForTextInput:nextTextInput] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        NSArray *textInputs = [self textInputs];
        NSInteger textInputIndex = [textInputs indexOfObject:self.currentTextView];
        UIView *nextTextInput = [textInputs objectAtIndex:textInputIndex+1];
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
    [formInputAccessoryView release];
    formInputAccessoryView = nil;
    [self setFormGroups:nil];
    self.currentTextView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    self.loadingView = nil;
    [self setFormGroups:nil];
    [formInputAccessoryView release];
    formInputAccessoryView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentTextView = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSArray *)formGroups {
    NSAssert(NO, @"Need to override method formGroups");
    return nil;
}

- (NSString *)command {
    NSAssert(NO, @"Need to override method command");
    return nil;  
}

- (NSDictionary *)parameters:(NSDictionary *)parameters {
    NSAssert(NO, @"Need to override method parameters:");
    return nil;   
}

#pragma mark - UITableView data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:indexPath.section];
    NSString *key = [formGroup keyForRow:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:key];
    LibraryFormElement *formElement = [formGroup formElementForKey:key];
    if (!cell) {
        cell = [formElement tableViewCell];
    }
    [formElement updateCell:cell];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:indexPath.section];
    NSString *key = [formGroup keyForRow:indexPath.row];
    LibraryFormElement *formElement = [formGroup formElementForKey:key];
    return [formElement heightForTableViewCell];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self nonHiddenFormGroups].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:section];
    return [formGroup numberOfRows];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:indexPath.section];
    LibraryFormElement *element = [[formGroup elements] objectAtIndex:indexPath.row];
    if ([element isKindOfClass:[MenuLibraryFormElement class]]) {
        LibraryMenuElementViewController *vc = [[[LibraryMenuElementViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        vc.menuElement = (MenuLibraryFormElement *)element;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([element isKindOfClass:[DedicatedViewTextLibraryFormElement class]]) {
        LibraryTextElementViewController *vc = 
        [[[LibraryTextElementViewController alloc] init] autorelease];
        vc.textElement = (DedicatedViewTextLibraryFormElement *)element;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([element isKindOfClass:[ExternalLinkLibraryFormElement class]]) {
        ExternalLinkLibraryFormElement *externalLink = (ExternalLinkLibraryFormElement *)element;
        if ([[UIApplication sharedApplication] canOpenURL:externalLink.url]) {
            [[UIApplication sharedApplication] openURL:externalLink.url];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:section];
    if (formGroup.headerText) {
        CGFloat height = [ExplanatorySectionLabel heightWithText:formGroup.headerText
                                                           width:self.view.frame.size.width
                                                            type:ExplanatorySectionFooter];
        return height;
    } else if (formGroup.name) {
        return GROUPED_SECTION_HEADER_HEIGHT;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!identityVerified) {
        return nil;
    }
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:section];
    if (formGroup.headerText) {
        ExplanatorySectionLabel *headerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionHeader] autorelease];
        headerLabel.text = formGroup.headerText;
        return headerLabel;
    } else if (formGroup.name) {
        return [UITableView groupedSectionHeaderWithTitle:formGroup.name];
    }
    return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:section];
    if (formGroup.footerText) {
        CGFloat height = [ExplanatorySectionLabel heightWithText:formGroup.footerText
                                                           width:self.view.frame.size.width
                                                            type:ExplanatorySectionFooter];
        return height;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!identityVerified) {
        return nil;
    }
    LibraryFormElementGroup *formGroup = [[self nonHiddenFormGroups] objectAtIndex:section];
    if (formGroup.footerText) {
        ExplanatorySectionLabel *footerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
        footerLabel.text = formGroup.footerText;
        return footerLabel;
    }
    return nil;
}


- (BOOL)formValid {
    for (LibraryFormElementGroup *formGroup in [self nonHiddenFormGroups]) {
        for (NSString *key in [formGroup keys]) {
            NSString *value = [formGroup getFormValueForKey:key];
            
            if ([formGroup valueRequiredForKey:key]) {
                if (![value length]) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (NSDictionary *)formValues {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (LibraryFormElementGroup *formGroup in [self nonHiddenFormGroups]) {
        for (NSString *key in [formGroup keys]) {
            NSString *value = [formGroup getFormValueForKey:key];
            if (value) {
                [params setObject:value forKey:key];
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Error submitting form" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void)submitForm:(NSDictionary *)parameters {
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:LibrariesTag
                                                                              command:[self command]
                                                                           parameters:parameters] autorelease];
    
    ThankYouViewController *thanksController = [[ThankYouViewController alloc] initWithMessage:nil];
    thanksController.title = @"Submitting";
    [self.navigationController pushViewController:thanksController animated:NO];
    [thanksController release];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        NSDictionary *jsonDict = jsonResult;
        BOOL success = [(NSNumber *)[jsonDict objectForKey:@"success"] boolValue];
        if (error || !success) {
            DLog(@"Request failed with error: %@",[error localizedDescription]);
            [self.navigationController popViewControllerAnimated:NO];
            [self showErrorSubmittingForm];
        } else {
            NSDictionary *resultsDict = [jsonDict objectForKey:@"results"];
            NSString *text = 
            [NSString 
             stringWithFormat:@"%@\n\nYou will be contacted at %@.", 
             [resultsDict objectForKey:@"thank_you_text"], 
             [resultsDict objectForKey:@"email"]];
            
            thanksController.title = @"Thank You";
            thanksController.message = text;
        }
    };

    [librariesModule.requestQueue addOperation:request];
}

- (LibraryFormElementGroup *)groupForName:(NSString *)name {
    for (LibraryFormElementGroup *formGroup in _formGroups) {
        if ([formGroup.name isEqualToString:name]) {
            return formGroup;
        }
    }
    return nil;
}

- (LibraryFormElement *)statusMenuFormElementWithRequired:(BOOL)required {
    return             
        [[[MenuLibraryFormElement alloc] initWithKey:@"status" 
                                        displayLabel:@"Status" 
                                            required:required
                                              values:[NSArray arrayWithObjects:
                                                      @"UG",
                                                      @"GRAD",
                                                      @"FAC",
                                                      @"RS",
                                                      @"STAFF",
                                                      @"VS",
                                                      nil] 
                                       displayValues:[NSArray arrayWithObjects:
                                                      @"MIT Undergrad Student",
                                                      @"MIT Grad Student",
                                                      @"MIT Faculty",
                                                      @"MIT Research Staff",
                                                      @"MIT Staff",
                                                      @"MIT Visitor",
                                                      nil]] autorelease];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // network error message being dismmised
    [self.navigationController popViewControllerAnimated:YES];
}
@end
