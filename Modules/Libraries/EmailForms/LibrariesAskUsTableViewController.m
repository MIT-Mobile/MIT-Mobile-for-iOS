#import "LibrariesAskUsTableViewController.h"
#import "LibrariesAskUsViewController.h"
#import "LibrariesAppointmentViewController.h"
#import "UIKit+MITAdditions.h"
#import "SecondaryGroupedTableViewCell.h"

#define ASK_US_ROW 0
#define APPOINTMENT_ROW 1
#define FORM_ROWS 2

#define PADDING 10

#define TEXT_WIDTH 260
#define ASK_US_TEXT @"Ask Us!"
#define APPOINTMENT_TEXT @"Make a research consultation appointment"

#define FORM_SECTION 0
#define HELP_SECTION 1
#define SECTIONS 2


@implementation LibrariesAskUsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];

    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }

    self.title = @"Ask Us";
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


- (CGFloat)heightForText:(NSString *)text {
    CGSize textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
                       constrainedToSize:CGSizeMake(260, 100)];
    return textSize.height;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == FORM_SECTION) {
        return FORM_ROWS;
    } else if (section == HELP_SECTION) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == FORM_SECTION) {
        static NSString *CellIdentifier = @"LockedCell";
    
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            cell.textLabel.numberOfLines = 0;
        }
    
        if (indexPath.row == ASK_US_ROW) {
            cell.textLabel.text = ASK_US_TEXT;
        } else if (indexPath.row == APPOINTMENT_ROW) {
            cell.textLabel.text = APPOINTMENT_TEXT;
        }
        return cell;
    } else if (indexPath.section == HELP_SECTION) {
        UITableViewCell *helpCell = [tableView dequeueReusableCellWithIdentifier:@"Help"];
        if (!helpCell) {
            helpCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Help"];
            helpCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            helpCell.textLabel.text = @"General help";
            helpCell.detailTextLabel.text = @"617.324.2275";
            helpCell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
        return helpCell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == FORM_SECTION) {
        NSString *text = nil;
        if (indexPath.row == ASK_US_ROW) {
            text = ASK_US_TEXT;
        } else if (indexPath.row == APPOINTMENT_ROW) {
            text = APPOINTMENT_TEXT;
        }
        return MAX([self heightForText:text] + 2 * PADDING, tableView.rowHeight);
    } else {
        // There's probably a better way to do this —
        // one that doesn't require hardcoding expected padding.
        
        // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
        static UIEdgeInsets labelInsets;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            labelInsets = UIEdgeInsetsMake(11., 15., 11., 34. + 2.);
        } else {
            labelInsets = UIEdgeInsetsMake(11., 10. + 10., 11., 10. + 39.);
        }
        
        NSString *title = @"General Help";
        NSString *detail = @"617.324.2275";
        
        CGFloat availableWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
        CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont buttonFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByTruncatingTail];
        
        return MAX(titleSize.height + detailSize.height + labelInsets.top + labelInsets.bottom, tableView.rowHeight);
    }
    return tableView.rowHeight;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.section == FORM_SECTION) {
        UIViewController *vc = nil;
        if (indexPath.row == ASK_US_ROW) {
            vc = [[LibrariesAskUsViewController alloc] init];
        } else if (indexPath.row == APPOINTMENT_ROW) {
            vc = [[LibrariesAppointmentViewController alloc] init];
        } 
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == HELP_SECTION) {
        NSURL *url = [NSURL URLWithString:@"tel://16173242275"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
