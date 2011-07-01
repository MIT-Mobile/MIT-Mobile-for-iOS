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
        CGRect  labelFrame = viewFrame;
        labelFrame.origin = CGPointZero;
        labelFrame.size.height = viewFrame.size.height * 0.33;
        UITextView *textView = [[[UITextView alloc] initWithFrame:labelFrame] autorelease];
        textView.backgroundColor = [UIColor clearColor];
        textView.editable = NO;
        textView.userInteractionEnabled = NO;
        textView.scrollEnabled = NO;
        textView.text = [NSString stringWithFormat:@"MIT Facilities does not maintain this building. Please contact %@ to report a problem.",self.location.propertyOwner.name];
        textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        [mainView addSubview:textView];
        self.messageView = textView;
    }

    {
        CGRect  tableFrame = viewFrame;
        tableFrame.origin = CGPointMake(0, viewFrame.size.height * 0.33 );
        tableFrame.size.height = viewFrame.size.height * 0.66;
        UITableView *tableView = [[[UITableView alloc] initWithFrame:tableFrame
                                                               style:UITableViewStyleGrouped] autorelease];
        [tableView applyStandardColors];
        tableView.delegate = self;
        tableView.dataSource = self;

        [mainView addSubview:tableView];
        self.contactsTable = [tableView autorelease];
    }
    
    [self setView:mainView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
        cell = [[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:cellReuseIdentifier];
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
