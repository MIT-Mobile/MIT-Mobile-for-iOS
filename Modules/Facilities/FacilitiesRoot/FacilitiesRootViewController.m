#import "FacilitiesRootViewController.h"

#import "FacilitiesCategoryViewController.h"
#import "UIKit+MITAdditions.h"
#import "SecondaryGroupedTableViewCell.h"
#import "MITTelephoneHandler.h"

static NSString* const kFacilitiesEmailAddress = @"txtdof@mit.edu";
static NSString* const kFacilitiesPhoneNumber = @"617.253.4948";

#pragma mark -
@implementation FacilitiesRootViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Building Services";
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.view.backgroundColor = [UIColor mit_backgroundColor];
    } else {
        CGRect textFrame = self.textView.frame;
        textFrame.origin.y += 64.;
        self.textView.frame = textFrame;
    }

    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        CGRect tableFrame = self.tableView.frame;
        tableFrame.origin.y += 44.;
        self.tableView.frame = tableFrame;
    }
    
    self.textView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.textView = nil;
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - UITableViewDelegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        default:
            return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reportCellIdentifier = @"FacilitiesCell";
    static NSString *contactCellIdentifier = @"ContactCell";

    UITableViewCell *cell = nil;

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:reportCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:reportCellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:contactCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                          reuseIdentifier:contactCellIdentifier];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
    }

    switch (indexPath.section) {
        case 0:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Report a Problem";
            break;
        }
        
        case 1:
        {
            UITableViewCell *customCell = (UITableViewCell *)cell;
            customCell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
            customCell.accessoryType = UITableViewCellAccessoryNone;
            customCell.textLabel.backgroundColor = [UIColor clearColor];
            customCell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            switch (indexPath.row) {
                case 0:
                    customCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                    customCell.textLabel.text = @"Email Facilities";
                    customCell.detailTextLabel.text = kFacilitiesEmailAddress;
                    break;
                case 1:
                    customCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                    customCell.textLabel.text =  @"Call Facilities";
                    customCell.detailTextLabel.text = kFacilitiesPhoneNumber;
                    break;
                default:
                    break;
            }
        }

        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            return 44.;

        default:
            return 60.;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        FacilitiesCategoryViewController *vc = [[FacilitiesCategoryViewController alloc] init];
        [self.navigationController pushViewController:vc
                                             animated:YES];
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                if ([MFMailComposeViewController canSendMail]) {
                    MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                    [mailView setMailComposeDelegate:self];
                    [mailView setSubject:@"Request from Building Services"];
                    [mailView setToRecipients:[NSArray arrayWithObject:kFacilitiesEmailAddress]];
                    [self presentViewController:mailView animated:YES completion:NULL];
                }
                break;
            }
                
            case 1:
            {
                [MITTelephoneHandler attemptToCallPhoneNumber:kFacilitiesPhoneNumber];
                break;
            }
            
            default:
                /* Do Nothing */
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

#pragma mark - MFMailComposeViewController delegation
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}
@end
