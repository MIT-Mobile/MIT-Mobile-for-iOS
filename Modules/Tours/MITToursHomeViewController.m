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
#import <MessageUI/MessageUI.h>

static NSString *const kMITSelfGuidedTourCell = @"MITToursSelfGuidedTourCell";
static NSString *const kMITInfoCell = @"MITToursInfoCell";

typedef NS_ENUM(NSInteger, MITToursTableViewSection) {
    MITToursTableViewSectionInfo,
    MITToursTableViewSectionLinks
};

@interface MITToursHomeViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MITToursLinksDataSourceDelegateDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) MITToursTour *selfGuidedTour;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITToursLinksDataSourceDelegate *linksDataSourceDelegate;

@end

@implementation MITToursHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Tours";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupTableView];
    
    [MITToursWebservices getToursWithCompletion:^(id object, NSError *error) {
        if ([object isKindOfClass:[NSArray class]]) {
            MITToursTour *tour = object[0];
            [MITToursWebservices getTourDetailForTour:tour completion:^(id object, NSError *error) {
                if ([object isKindOfClass:[MITToursTour class]]) {
                    self.selfGuidedTour = object;
                    [self.tableView reloadData];
                }
            }];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
    
    if ([[UIApplication sharedApplication] statusBarOrientation] != UIInterfaceOrientationPortrait) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        
        //will re-rotate view according to statusbar -- Apparently this is necessary ...
        UIViewController *c = [[UIViewController alloc]init];
        [self presentViewController:c animated:NO completion:nil];
        [c dismissViewControllerAnimated:NO completion:nil];
        [self.tableView reloadData];
    }
}

- (void)setupTableView
{
    self.linksDataSourceDelegate = [[MITToursLinksDataSourceDelegate alloc] init];
    self.linksDataSourceDelegate.isIphoneTableView = YES;
    self.linksDataSourceDelegate.delegate = self;

    UINib *cellNib = [UINib nibWithNibName:kMITSelfGuidedTourCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITSelfGuidedTourCell];
    
    cellNib = [UINib nibWithNibName:kMITInfoCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITInfoCell];
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, -1, 1, 1)];
    self.tableView.tableHeaderView = containerView;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITToursTableViewSectionInfo) {
        switch (indexPath.row) {
            case 0:
                return (tableView.frame.size.width / 320.0) * 229.0; // Sizes image properly for iPhone 6
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == MITToursTableViewSectionInfo) {
        return 3;
    }
    else if (section == MITToursTableViewSectionLinks) {
        return [self.linksDataSourceDelegate tableView:tableView numberOfRowsInSection:section];
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
    
    if (self.selfGuidedTour) {
        [cell setTour:self.selfGuidedTour];
    }
    
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
        if (indexPath.row == 0 && self.selfGuidedTour) {
            MITToursSelfGuidedTourContainerController *tourVC = [[MITToursSelfGuidedTourContainerController alloc] initWithTour:self.selfGuidedTour];
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

#pragma mark - Rotation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
