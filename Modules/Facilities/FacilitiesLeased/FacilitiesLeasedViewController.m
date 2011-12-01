#import "FacilitiesLeasedViewController.h"
#import "FacilitiesLocation.h"
#import "FacilitiesPropertyOwner.h"
#import "SecondaryGroupedTableViewCell.h"
#import "UIKit+MITAdditions.h"

enum {
    FacilitiesLeasedNoneTag = 0,
    FacilitiesLeasedEmailTag,
    FacilitiesLeasedPhoneTag
};

@interface FacilitiesLeasedViewController ()
@property (nonatomic, retain) FacilitiesLocation *location;
@end

@implementation FacilitiesLeasedViewController
@synthesize location = _location;
@synthesize contactsTable = _contactsTable;
@synthesize messageView = _messageView;

- (id)initWithLocation:(FacilitiesLocation*)location
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        self.location = location;
    }
    return self;
}

- (void)dealloc {
    self.location = nil;
    self.contactsTable = nil;
    self.messageView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle
- (void)loadView
{
    CGRect viewFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];

    {
        CGFloat margin = 20.0;
        CGRect labelFrame = CGRectZero;
        UILabel *labelView = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        labelView.backgroundColor = [UIColor clearColor];
        labelView.userInteractionEnabled = NO;
        labelView.lineBreakMode = UILineBreakModeWordWrap;
        labelView.numberOfLines = 0;
        labelView.text = [NSString stringWithFormat:@"The Department of Facilities is not responsible for the maintenance of %@. Please contact %@ to report any issues.", [self.location displayString], self.location.propertyOwner.name];
        
        CGSize fittedSize = [labelView sizeThatFits:CGSizeMake(viewFrame.size.width - (2.0 * margin), 2000.0)];
        labelFrame.origin = CGPointMake(margin, margin);
        labelFrame.size = fittedSize;
        labelView.frame = labelFrame;

        [mainView addSubview:labelView];
        self.messageView = labelView;
    }

    {
        CGRect tableFrame = CGRectZero;
        tableFrame.origin = CGPointMake(0, floor(CGRectGetMaxY(self.messageView.frame) + 10.0));
        tableFrame.size = CGSizeMake(viewFrame.size.width, viewFrame.size.height - tableFrame.origin.y);
        UITableView *tableView = [[[UITableView alloc] initWithFrame:tableFrame
                                                               style:UITableViewStyleGrouped] autorelease];
        [tableView applyStandardColors];
        tableView.delegate = self;
        tableView.dataSource = self;

        [mainView addSubview:tableView];
        self.contactsTable = tableView;
    }
    
    [self setView:mainView];
    
    self.title = @"Where is it?";
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
                [self.navigationController presentModalViewController:mailView
                                                             animated:YES]; 
            }
            break;
        }
            
        case FacilitiesLeasedPhoneTag:
        {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://1%@",self.location.propertyOwner.phone]];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
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
    
    SecondaryGroupedTableViewCell *cell = (SecondaryGroupedTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    
    if (cell == nil) {
        cell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:cellReuseIdentifier] autorelease];
        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    
    switch (indexPath.row) {
        case 0:
            if ([self.location.propertyOwner.email length] > 0) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                cell.textLabel.text = @"Email";
                cell.tag = FacilitiesLeasedEmailTag;
                cell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@)",self.location.propertyOwner.email];
            } else if ([self.location.propertyOwner.phone length] > 0) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                cell.textLabel.text = @"Call";
                cell.tag = FacilitiesLeasedPhoneTag;
                
                NSString *phone = self.location.propertyOwner.phone;
                cell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@.%@.%@)",
                                                [phone substringToIndex:3],
                                                [phone substringWithRange:NSMakeRange(3, 3)],
                                                [phone substringFromIndex:6]];
            }
            break;
        case 1:
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.textLabel.text = @"Email";
            cell.tag = FacilitiesLeasedEmailTag;
            cell.secondaryTextLabel.text = [NSString stringWithFormat:@"(%@)",self.location.propertyOwner.email];
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
    [self.navigationController dismissModalViewControllerAnimated:YES];
}
@end
