
#import "MITLibrariesFormSheetViewController.h"
#import "MITLibrariesFormSheetCellOptions.h"
#import "MITLibrariesFormSheetCellSingleLineTextEntry.h"
#import "MITLibrariesFormSheetCellMultiLineTextEntry.h"
#import "MITLibrariesFormSheetCellWebLink.h"

#import "UIKit+MITAdditions.h"
#import "MITTouchstoneController.h"

static NSString * const MITLibrariesFormSheetCellIdentifierOptions = @"MITLibrariesFormSheetCellIdentifierOptions";
static NSString * const MITLibrariesFormSheetCellIdentifierSingleLineTextEntry = @"MITLibrariesFormSheetCellIdentifierSingleLineTextEntry";
static NSString * const MITLibrariesFormSheetCellIdentifierMultiLineTextEntry = @"MITLibrariesFormSheetCellIdentifierMultiLineTextEntry";
static NSString * const MITLibrariesFormSheetCellIdentifierWebLink = @"MITLibrariesFormSheetCellIdentifierWebLink";

static NSString * const MITLibrariesFormSheetViewControllerNibName = @"MITLibrariesFormSheetViewController";

@interface MITLibrariesFormSheetViewController () <UITableViewDataSource, UITableViewDelegate, MITLibrariesFormSheetTextEntryCellDelegate>
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

#pragma mark - Setup

- (void)setup
{
    [self setupActivityIndicator];
    [self setupTableView];
    [self setupNavigationBar];
    [self verifyAuthorization];
}

- (void)setupActivityIndicator
{
    self.activityIndicator.color = [UIColor mit_tintColor];
}

- (void)setupTableView
{
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

#pragma mark - Authorization

- (void)verifyAuthorization
{
    self.tableView.hidden = YES;
    if (![[MITTouchstoneController sharedController] isLoggedIn]) {
        [[MITTouchstoneController sharedController] login:^(BOOL success, NSError *error) {
            if (error || !success) {
                NSLog(@"Login Failed w/ Error: %@", error);
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                self.tableView.hidden = NO;
            }
        }];
    } else {
        self.tableView.hidden = NO;
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
    [self submitFormForParameters:[self formAsHTMLParametersDictionary]];
}

#pragma mark - Form Submission

- (void)submitFormForParameters:(NSDictionary *)parameters
{
    NSLog(@"FORM SHEET VIEW CONTROLLER: Should be implemented by subclass");
}

- (NSDictionary *)formAsHTMLParametersDictionary
{
    NSMutableDictionary *formDict = [NSMutableDictionary dictionary];
    for (MITLibrariesFormSheetGroup *group in self.formSheetGroups) {
        for (MITLibrariesFormSheetElement *element in group.elements) {
            if (element.value && element.htmlParameterKey) {
                formDict[element.htmlParameterKey] = element.htmlParameterValue;
            } else if (!element.optional) {
                NSLog(@"ERROR: Required form sheet element has no value! %@", element.title);
            }
        }
    }
    return formDict;
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
    
    NSString *title = @"Success!";
    NSString *confirmation = @"Ok";
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
            optionsSelectorVC.delegate = self;
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
        default:
            // Ignore other touches
            break;
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

#pragma mark - MITLibrariesFormSheetOptionsSelectionViewControllerDelegate

- (void)formSheetOptionsSelectionViewController:(MITLibrariesFormSheetOptionsSelectionViewController *)optionsSelectionViewController didFinishUpdatingElement:(MITLibrariesFormSheetElement *)element
{
    [self.navigationController popViewControllerAnimated:YES];
    [self reloadTableView];
}

@end
