#import "AboutTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "AboutMITVC.h"
#import "AboutCreditsVC.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"

@implementation AboutTableViewController

- (void)viewDidLoad {
    [self.tableView applyStandardColors];
    showBuildNumber = NO;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 20, 45)];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, footerView.frame.size.width, 30)];
    footerLabel.text = @"Copyright © 2010 Massachusetts Institute of Technology. All rights reserved.";
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.textColor = CELL_DETAIL_FONT_COLOR;
    footerLabel.font = [UIFont systemFontOfSize:12.0];
    footerLabel.lineBreakMode = UILineBreakModeWordWrap;
    footerLabel.numberOfLines = 0;
    [footerView addSubview:footerLabel];
    self.tableView.tableFooterView = footerView;
    [footerLabel release];
    [footerView release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 3;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1) {
        NSString *aboutText = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITAboutAppText"];
        UIFont *aboutFont = [UIFont systemFontOfSize:14.0];
        CGSize aboutSize = [aboutText sizeWithFont:aboutFont constrainedToSize:CGSizeMake(270, 2000) lineBreakMode:UILineBreakModeWordWrap];
        return aboutSize.height + 20;
    }
    else {
        return self.tableView.rowHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    if (!showBuildNumber) {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"]];
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"], MITBuildNumber];
                    }
                    cell.textLabel.textAlignment = UITextAlignmentCenter;
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        			cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                case 1:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    cell.textLabel.text = [infoDict objectForKey:@"MITAboutAppText"];
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        			cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Credits";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    break;
                case 1:
                    cell.textLabel.text = @"About MIT";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    break;
                case 2:
                    cell.textLabel.text = @"Send Feedback";
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                break;
            }
        default:
            break;
    }
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        showBuildNumber = !showBuildNumber;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {
                AboutCreditsVC *aboutCreditsVC = [[AboutCreditsVC alloc] init];
                [self.navigationController pushViewController:aboutCreditsVC animated:YES];
                [aboutCreditsVC release];
                break;
            }
            case 1: {
                AboutMITVC *aboutMITVC = [[AboutMITVC alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:aboutMITVC animated:YES];
                [aboutMITVC release];
                break;
            }
            case 2: {
                Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
                NSString *subject = [NSString stringWithFormat:@"Feedback for MIT Mobile %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], MITBuildNumber];
                if ((mailClass != nil) && [mailClass canSendMail]) {
                    
                    MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
                    aController.mailComposeDelegate = self;
                    
                    [aController setSubject:subject];
                    [aController setToRecipients:[NSArray arrayWithObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITFeedbackAddress"]]];
                    
                    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
                    [appDelegate presentAppModalViewController:aController animated:YES];
                    [aController release];
                    
                } else {
                    NSString *mailtoString = [NSString stringWithFormat:@"mailto://?subject=%@", subject];
                    
                    NSURL *externURL = [NSURL URLWithString:mailtoString];
                    if ([[UIApplication sharedApplication] canOpenURL:externURL])
                        [[UIApplication sharedApplication] openURL:externURL];
                }
            }            
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark MFMailComposeViewController delegation

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
    [self viewWillAppear:NO];
}

- (void)dealloc {
    [super dealloc];
}


@end

