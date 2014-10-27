#import "MITToursHomeViewController.h"
#import "MITToursWebservices.h"
#import "UIKit+MITAdditions.h"
#import "MITToursTour.h"
#import "UIFont+MITTours.h"
#import "MITToursSelfGuidedTourCell.h"
#import "MITToursInfoCell.h"

static NSString *const kMITSelfGuidedTourCell = @"MITToursSelfGuidedTourCell";
static NSString *const kMITInfoCell = @"MITToursInfoCell";
static NSString *const kMITLinkCell = @"kMITLinkCell";

// These are hardcoded for now, but will be replaced by webservice calls when those become available
static NSString *const kAboutGuidedToursText = @"Regularly scheduled studen-led campus tours are conducted Monday through Friday at 11 am and at 3 pm, excluding legal US holidays and the winter break period.";
static NSString *const kAboutMITText = @"The misson of MIT is to advance knowledge and educate students in science, technology, and otehr areas of scholarship that will best serve the nation and the world in the 21st century.";

static NSString *const kAboutMITURL = @"http://web.mit.edu/institute-events/events/";

@interface MITToursHomeViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) MITToursTour *selfGuidedTour;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MITToursHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Tours";
    
    [self.activityIndicator startAnimating];
    
    [self setupTableView];
    
    [MITToursWebservices getToursWithCompletion:^(id object, NSError *error) {
        if (object) {
            MITToursTour *tour = object[0];
            [MITToursWebservices getTourDetailForTour:tour completion:^(id object, NSError *error) {
                if ([object isKindOfClass:[MITToursTour class]]) {
                    self.selfGuidedTour = object;
                    [self updateDisplayedTour];
                }
            }];
        }
    }];
}

- (void)setupTableView
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 110)];
    UIImage *headerImage = [UIImage imageNamed:@"tours/tours_cover_image.jpg"];
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];

    [headerImageView setImage:headerImage];
    [headerImageView setContentMode:UIViewContentModeScaleAspectFill];
    [containerView addSubview:headerImageView];
    
    self.tableView.tableHeaderView = containerView;
    [self.tableView sendSubviewToBack:self.tableView.tableHeaderView];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UINib *cellNib = [UINib nibWithNibName:kMITSelfGuidedTourCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITSelfGuidedTourCell];
    
    cellNib = [UINib nibWithNibName:kMITInfoCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITInfoCell];
}

- (void)updateDisplayedTour
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                return 106.0;
                break;
            case 1:
                return [MITToursInfoCell heightForContent:kAboutGuidedToursText tableViewWidth:self.tableView.frame.size.width];
                break;
            case 2:
                return [MITToursInfoCell heightForContent:kAboutMITText tableViewWidth:self.tableView.frame.size.width];
                break;
            default:
                break;
        }
    }
    return 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.selfGuidedTour) {
        return 2;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.selfGuidedTour) {
        if (section == 0) {
            return 3;
        }
        else if (section == 1) {
            return 3;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        switch (indexPath.row) {
            case 0:
                return [self selfGuidedTourCell];
                break;
            case 1:
                return [self moreAboutToursCell];
                break;
                case 2:
                return [self moreAboutMITCell];
            default:
                break;
        }
    }
    else if (indexPath.section == 1) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITLinkCell];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITLinkCell];
        }
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Send Feedback";
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                break;
            case 1:
                cell.textLabel.text = @"MIT Information Center";
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                break;
            case 2:
                cell.textLabel.text = @"MIT Admissions";
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
                break;
                
            default:
                break;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (UITableViewCell *)selfGuidedTourCell
{
    MITToursSelfGuidedTourCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITSelfGuidedTourCell];
    
    [cell setTour:self.selfGuidedTour];
    
    return cell;
}

- (UITableViewCell *)moreAboutToursCell
{
    MITToursInfoCell *cell = [self blankInfoCell];
    
    [cell setContent:kAboutGuidedToursText];
    [cell.infoButton setTitle:@"More about guided tours..." forState:UIControlStateNormal];
    [cell.infoButton addTarget:self action:@selector(moreAboutToursPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (UITableViewCell *)moreAboutMITCell
{
    MITToursInfoCell *cell = [self blankInfoCell];
    
    [cell setContent:kAboutMITText];
    [cell.infoButton setTitle:@"More about MIT..." forState:UIControlStateNormal];
    [cell.infoButton addTarget:self action:@selector(moreAboutMITPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (MITToursInfoCell *)blankInfoCell
{
    MITToursInfoCell *cell  = [self.tableView dequeueReusableCellWithIdentifier:kMITInfoCell];
    
    [cell.infoButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    return cell;
}

- (void)moreAboutToursPressed:(UIButton *)sender
{
    // TODO: Push to detail view
}

- (void)moreAboutMITPressed:(UIButton *)sender
{
   UIAlertView *openOutsideWebsiteAlert = [[UIAlertView alloc] initWithTitle:@"Open in Safari?" message:kAboutMITURL delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
    [openOutsideWebsiteAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAboutMITURL]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    // TODO: push to detail views
}

@end
