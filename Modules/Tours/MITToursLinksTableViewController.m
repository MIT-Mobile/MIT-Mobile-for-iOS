#import "MITToursLinksTableViewController.h"
#import "MITToursLinksDataSourceDelegate.h"
#import "MITMailComposeController.h"

@interface MITToursLinksTableViewController () <MITToursLinksDataSourceDelegateDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) MITToursLinksDataSourceDelegate *tableViewDataSourceDelegate;

@end

@implementation MITToursLinksTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Links";
    
    self.tableView.scrollEnabled = NO;
    
    [self setupDataSourceDelegate];
}

- (void)setupDataSourceDelegate
{
    self.tableViewDataSourceDelegate = [[MITToursLinksDataSourceDelegate alloc] init];
    self.tableView.dataSource = self.tableViewDataSourceDelegate;
    self.tableView.delegate = self.tableViewDataSourceDelegate;
    
    self.tableViewDataSourceDelegate.delegate = self;
}

- (void)presentMailViewController:(MFMailComposeViewController *)mailViewController
{
    mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    mailViewController.mailComposeDelegate = self;
   [self presentViewController:mailViewController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end
