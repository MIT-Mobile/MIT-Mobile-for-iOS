#import "FacilitiesLeasedViewController.h"
#import "FacilitiesLocation.h"
#import "FacilitiesPropertyOwner.h"
#import "UIKit+MITAdditions.h"
#import "MITTelephoneHandler.h"

enum {
    FacilitiesLeasedNoneTag = 0,
    FacilitiesLeasedEmailTag,
    FacilitiesLeasedPhoneTag
};

@interface FacilitiesLeasedViewController ()
@property (nonatomic, strong) FacilitiesLocation *location;
@end

@implementation FacilitiesLeasedViewController
- (id)initWithLocation:(FacilitiesLocation*)location
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        self.location = location;
    }
    return self;
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[UIView alloc] initWithFrame:viewFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        mainView.backgroundColor = [UIColor mit_backgroundColor];
    }

    {
        CGFloat margin = 20.0;
        CGRect labelFrame = CGRectZero;
        UILabel *labelView = [[UILabel alloc] initWithFrame:labelFrame];
        labelView.backgroundColor = [UIColor clearColor];
        labelView.userInteractionEnabled = NO;
        labelView.lineBreakMode = NSLineBreakByWordWrapping;
        labelView.numberOfLines = 0;
        labelView.text = [NSString stringWithFormat:@"The Department of Facilities is not responsible for the maintenance of %@. Please contact %@ to report any issues.", [self.location displayString], self.location.propertyOwner.name];
        
        CGSize fittedSize = [labelView sizeThatFits:CGSizeMake(viewFrame.size.width - (2.0 * margin), 2000.0)];
        labelFrame.origin = CGPointMake(margin, margin);
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            labelFrame.origin.y += 64.;
        }
        
        labelFrame.size = fittedSize;
        labelView.frame = labelFrame;

        
        [mainView addSubview:labelView];
        self.messageView = labelView;
    }

    {
        CGRect tableFrame = CGRectZero;
        tableFrame.origin = CGPointMake(0, floor(CGRectGetMaxY(self.messageView.frame) + 10.0));
        tableFrame.size = CGSizeMake(viewFrame.size.width, viewFrame.size.height - tableFrame.origin.y);
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            tableFrame.origin.y += 64.;
            tableFrame.size.height -= 64.;
        }

        UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame
                                                              style:UITableViewStyleGrouped];
        [tableView applyStandardColors];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.scrollEnabled = NO;
        tableView.rowHeight = 60.;
        
        [mainView addSubview:tableView];
        self.contactsTable = tableView;
    }
    
    [self setView:mainView];
    
    self.title = @"Where is it?";
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag) {
        case FacilitiesLeasedEmailTag:
        {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
                [mailView setMailComposeDelegate:self];
                [mailView setSubject:@"Request from Building Services"];
                [mailView setToRecipients:[NSArray arrayWithObject:self.location.propertyOwner.email]];
                [self.navigationController presentViewController:mailView animated:YES completion:NULL];
            }
            break;
        }
            
        case FacilitiesLeasedPhoneTag:
        {
            [MITTelephoneHandler attemptToCallPhoneNumber:self.location.propertyOwner.phone];
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}


#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    
    if ([self.location.propertyOwner.email length] > 0) {
        ++rowCount;
    }
    
    if ([self.location.propertyOwner.phone length] > 0) {
        ++rowCount;
    }
    
    return rowCount;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellReuseIdentifier = @"FacilitiesLeasedTableViewCell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                    reuseIdentifier:cellReuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }
    
    switch (indexPath.row) {
        case 0:
            if ([self.location.propertyOwner.email length] > 0) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                cell.textLabel.text = @"Email";
                cell.tag = FacilitiesLeasedEmailTag;
                cell.detailTextLabel.text = self.location.propertyOwner.email;
            } else if ([self.location.propertyOwner.phone length] > 0) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                cell.textLabel.text = @"Call";
                cell.tag = FacilitiesLeasedPhoneTag;
                
                NSString *phone = self.location.propertyOwner.phone;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@.%@.%@",
                                                [phone substringToIndex:3],
                                                [phone substringWithRange:NSMakeRange(3, 3)],
                                                [phone substringFromIndex:6]];
            }
            break;
        case 1:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.textLabel.text = @"Email";
            cell.tag = FacilitiesLeasedEmailTag;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",self.location.propertyOwner.email];
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}
@end
