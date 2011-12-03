#import "AboutTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "AboutMITVC.h"
#import "AboutCreditsVC.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MITMailComposeController.h"
#import "MITBuildInfo.h"
#import  <QuartzCore/CALayer.h>
#import "ExplanatorySectionLabel.h"

@implementation AboutTableViewController

- (void)viewDidLoad {
    [self.tableView applyStandardColors];
    self.title = @"About";
    
    showBuildNumber = NO;
}

#pragma mark - UITableView Data Source

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
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                    cell.textLabel.textAlignment = UITextAlignmentCenter;
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        			cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    if (!showBuildNumber) {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [infoDict objectForKey:@"CFBundleDisplayName"], [infoDict objectForKey:@"CFBundleVersion"]];
                    } else {
                        cell.textLabel.text = [MITBuildInfo description];
                        
                        CGImageRef hashImage = [MITBuildInfo newHashImage];
                        
                        // turn off smooth scaling because hashImage starts as tiny pixel art
                        [[cell.imageView layer] setMagnificationFilter:kCAFilterNearest];
                        CGFloat imageWidth = (CGFloat)CGImageGetWidth(hashImage);
                        CGFloat desiredWidth = 30.0;
                        cell.imageView.image = [UIImage imageWithCGImage:hashImage 
                                                                   scale:imageWidth / desiredWidth 
                                                             orientation:UIImageOrientationUp];
                        CGImageRelease(hashImage);
                    }
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

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        showBuildNumber = !showBuildNumber;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
                NSString *email = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITFeedbackAddress"];
                NSString *subject = [NSString stringWithFormat:@"Feedback for MIT Mobile %@ (%@) on %@ %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [MITBuildInfo description], [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
                
                if ([MFMailComposeViewController canSendMail]) {
                    MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                    [mailView setMailComposeDelegate:self];
                    [mailView setSubject:subject];
                    [mailView setToRecipients:[NSArray arrayWithObject:email]];
                    [self presentModalViewController:mailView
                                            animated:YES]; 
                }            
            }
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    switch (section) {
        case 1: {
            ExplanatorySectionLabel *copyrightFooter = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
            copyrightFooter.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITCopyright"];
            copyrightFooter.fontSize = 12.0;
            return copyrightFooter;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    switch (section) {
        case 1: {
            NSString *copyrightText = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITCopyright"];
            return [ExplanatorySectionLabel heightWithText:copyrightText width:CGRectGetWidth(tableView.bounds) type:ExplanatorySectionFooter accessoryView:nil fontSize:12.0];
        }
    }
    return 0;
}

#pragma mark - MFMailComposeViewController delegation
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	[self dismissModalViewControllerAnimated:YES];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
}

@end

