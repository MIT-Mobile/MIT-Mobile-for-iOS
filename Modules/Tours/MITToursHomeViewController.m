#import "MITToursHomeViewController.h"
#import "MITToursWebservices.h"
#import "UIKit+MITAdditions.h"
#import "MITToursTour.h"
#import "UIFont+MITTours.h"
#import "MITToursSelfGuidedTourCell.h"
#import "MITToursInfoCell.h"
#import "MITToursAboutMITViewController.h"
#import "MITToursSelfGuidedTourContainerController.h"
#import "MITToursLinksDataSourceDelegate.h"
#import "MITMailComposeController.h"

static NSString *const kMITSelfGuidedTourCell = @"MITToursSelfGuidedTourCell";
static NSString *const kMITInfoCell = @"MITToursInfoCell";

typedef NS_ENUM(NSInteger, MITToursTableViewSection) {
    MITToursTableViewSectionInfo,
    MITToursTableViewSectionLinks
};

@interface MITToursHomeViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MITToursLinksDataSourceDelegateDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) MITToursTour *selfGuidedTour;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITToursLinksDataSourceDelegate *linksDataSourceDelegate;

@end

@implementation MITToursHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Tours";
    
    [self.activityIndicator startAnimating];
    
    [self setupTableView];
    
    [MITToursWebservices getToursWithCompletion:^(id object, NSError *error) {
        if ([object isKindOfClass:[NSArray class]]) {
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

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

- (void)setupTableView
{
    self.linksDataSourceDelegate = [[MITToursLinksDataSourceDelegate alloc] init];
    self.linksDataSourceDelegate.delegate = self;
    
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
        
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursTableViewSectionInfo) {
        switch (indexPath.row) {
            case 0:
                return 106.0;
                break;
            case 1:
                return [MITToursInfoCell heightForContent:[MITToursWebservices aboutGuidedToursText] tableViewWidth:self.tableView.frame.size.width];
                break;
            case 2:
                return [MITToursInfoCell heightForContent:[MITToursWebservices aboutMITText] tableViewWidth:self.tableView.frame.size.width];
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
        if (section == MITToursTableViewSectionInfo) {
            return 3;
        }
        else if (section == MITToursTableViewSectionLinks) {
            return [self.linksDataSourceDelegate tableView:tableView numberOfRowsInSection:section];
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursTableViewSectionInfo){
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
    else if (indexPath.section == MITToursTableViewSectionLinks) {
        return [self.linksDataSourceDelegate tableView:tableView cellForRowAtIndexPath:indexPath];
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
    
    cell.separatorView.hidden = YES;
    [cell setContent:[MITToursWebservices aboutGuidedToursText]];
    [cell.infoButton setTitle:@"More about guided tours..." forState:UIControlStateNormal];
    [cell.infoButton addTarget:self action:@selector(moreAboutToursPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (UITableViewCell *)moreAboutMITCell
{
    MITToursInfoCell *cell = [self blankInfoCell];
    
    cell.separatorView.hidden = NO;
    [cell setContent:[MITToursWebservices aboutMITText]];
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
    UIAlertView *openOutsideWebsiteAlert = [[UIAlertView alloc] initWithTitle:@"Open in Safari?" message:[MITToursWebservices aboutMITURLString] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
    [openOutsideWebsiteAlert show];
}

- (void)moreAboutMITPressed:(UIButton *)sender
{
    MITToursAboutMITViewController *aboutVC = [[MITToursAboutMITViewController alloc] init];
    [self.navigationController pushViewController:aboutVC animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[MITToursWebservices aboutMITURLString]]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == MITToursTableViewSectionInfo) {
        if (indexPath.row == 0) {
            MITToursSelfGuidedTourContainerController *tourVC = [[MITToursSelfGuidedTourContainerController alloc] init];
            tourVC.selfGuidedTour = self.selfGuidedTour;
            [self.navigationController pushViewController:tourVC animated:YES];
        }
    }
    else {
        [self.linksDataSourceDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)presentMailViewController:(MFMailComposeViewController *)mailViewController
{
    mailViewController.mailComposeDelegate = self;
    [self presentViewController:mailViewController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end