#import "MITToursLinksDataSourceDelegate.h"
#import "UIKit+MITAdditions.h"
#import "UIFont+MITTours.h"
#import "MITMailComposeController.h"
#import "MITBuildInfo.h"

typedef NS_ENUM(NSInteger, MITToursLinksCell) {
    MITToursLinksCellFeedback,
    MITToursLinksCellInformationCenter,
    MITToursLinksCellAdmissions
};

static NSString *const kMITLinkCell = @"kMITLinkCell";

@implementation MITToursLinksDataSourceDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITLinkCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITLinkCell];
        cell.textLabel.font = [UIFont toursTitle];
    }
    
    switch (indexPath.row) {
        case MITToursLinksCellFeedback:
        {
            cell.textLabel.text = @"Send Feedback";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            UIView *topSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, 0.5)];
            topSeparator.backgroundColor = [UIColor lightGrayColor];
            [cell addSubview:topSeparator];
            UIView *bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(15, cell.frame.size.height - 1, cell.frame.size.width - 15, 0.5)];
            bottomSeparator.backgroundColor = [UIColor lightGrayColor];
            [cell addSubview:bottomSeparator];
            break;
        }
        case MITToursLinksCellInformationCenter:
        {
            cell.textLabel.text = @"MIT Information Center";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            UIView *bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(15, cell.frame.size.height - 1, cell.frame.size.width - 15, 0.5)];
            bottomSeparator.backgroundColor = [UIColor lightGrayColor];
            [cell addSubview:bottomSeparator];
            break;
        }
        case MITToursLinksCellAdmissions:
        {
            cell.textLabel.text = @"MIT Admissions";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            UIView *bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, cell.frame.size.height - 1, cell.frame.size.width, 0.5)];
            bottomSeparator.backgroundColor = [UIColor lightGrayColor];
            [cell addSubview:bottomSeparator];
            break;
        }
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
   
    switch (indexPath.row) {
        case MITToursLinksCellFeedback:
            [self sendFeedback];
            break;
        case MITToursLinksCellInformationCenter:
            [self openURLString:@"http://web.mit.edu/institute-events/events/"];
            break;
        case MITToursLinksCellAdmissions:
            [self openURLString:@"http://mitadmissions.org/"];
            break;
        default:
            break;
    }
}

- (void)sendFeedback
{
    if ([self.delegate respondsToSelector:@selector(presentMailViewController:)] && [MFMailComposeViewController canSendMail]) {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *email = infoDict[@"MITFeedbackAddress"];
        NSString *subject = [NSString stringWithFormat:@"Feedback for MIT Mobile %@ (%@) on %@ %@", infoDict[@"CFBundleVersion"], [MITBuildInfo description], [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
        
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        [mailComposer setSubject:subject];
        [mailComposer setToRecipients:@[email]];
        [self.delegate presentMailViewController:mailComposer];
    }
}

- (void)openURLString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
