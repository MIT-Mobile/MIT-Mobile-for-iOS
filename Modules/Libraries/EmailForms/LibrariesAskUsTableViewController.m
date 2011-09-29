#import "LibrariesAskUsTableViewController.h"
#import "LibrariesAskUsViewController.h"
#import "LibrariesAppointmentViewController.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#import "SecondaryGroupedTableViewCell.h"

#define ASK_US_ROW 0
#define APPOINTMENT_ROW 1
#define FORM_ROWS 2

#define TEXT_TAG 1

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

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView applyStandardColors];
    [self.tableView applyStandardCellHeight];
    
    self.title = @"Ask Us!";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (CGFloat)heightForText:(NSString *)text {
    CGSize textSize = [text sizeWithFont:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] 
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
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING, TEXT_WIDTH, 200)] autorelease];
            label.textColor = CELL_STANDARD_FONT_COLOR;
            label.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
            label.tag = TEXT_TAG;
            label.numberOfLines = 0;
            label.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:label];
        }
    
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:TEXT_TAG];
        if (indexPath.row == ASK_US_ROW) {
            titleLabel.text = ASK_US_TEXT;
        } else if (indexPath.row == APPOINTMENT_ROW) {
            titleLabel.text = APPOINTMENT_TEXT;
        }
        CGRect titleLabelFrame = titleLabel.frame;
        titleLabelFrame.size.height = [self heightForText:titleLabel.text];
        titleLabel.frame = titleLabelFrame;
        return cell;
    } else if (indexPath.section == HELP_SECTION) {
        SecondaryGroupedTableViewCell *helpCell = (SecondaryGroupedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Help"];
        if (!helpCell) {
            helpCell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Help"] autorelease];
            helpCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            helpCell.textLabel.text = @"General help";
            helpCell.secondaryTextLabel.text = @"(617-324-2275)";
        }
        return helpCell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == FORM_SECTION) {
        if (indexPath.row == ASK_US_ROW) {
            return [self heightForText:ASK_US_TEXT] + 2 * PADDING;
        } else if (indexPath.row == APPOINTMENT_ROW) {
            return [self heightForText:APPOINTMENT_TEXT] + 2 * PADDING;
        }
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
            vc = [[[LibrariesAskUsViewController alloc] init] autorelease];
        } else if (indexPath.row == APPOINTMENT_ROW) {
            vc = [[[LibrariesAppointmentViewController alloc] init] autorelease];
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
