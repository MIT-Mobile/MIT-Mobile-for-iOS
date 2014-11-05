
#import "MITLibrariesAskUsHomeViewController.h"
#import "UIKit+MITAdditions.h"


#import "LibrariesAskUsViewController.h"
#import "LibrariesAppointmentViewController.h"

#import "MITLibrariesAskUsFormSheetViewController.h"

static NSString * const MITLibrariesAskUsHomeViewControllerCellIdentifier = @"MITLibrariesAskUsHomeViewControllerCellIdentifier";

typedef NS_ENUM(NSInteger, AskUsOption) {
    AskUsOptionAskUs,
    AskUsOptionConsultation,
    AskUsOptionGeneral,
    
    AskUsOptionAvailableOptionsCount
};

@interface MITLibrariesAskUsHomeTableViewCell : UITableViewCell
@end
@implementation MITLibrariesAskUsHomeTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return self;
}
@end

@interface MITLibrariesAskUsHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *askUsOptionsTableView;
@end

@implementation MITLibrariesAskUsHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setup
{
    [self setupTableView];
}

- (void)setupTableView
{
    [self.askUsOptionsTableView registerClass:[MITLibrariesAskUsHomeTableViewCell class] forCellReuseIdentifier:MITLibrariesAskUsHomeViewControllerCellIdentifier];
    self.askUsOptionsTableView.tableFooterView = [UIView new]; // Prevent empty cells
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return AskUsOptionAvailableOptionsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesAskUsHomeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITLibrariesAskUsHomeViewControllerCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [self titleTextForIndexPath:indexPath];
    cell.detailTextLabel.text = [self detailTextForIndexPath:indexPath];
    cell.accessoryView = [self accessoryViewForIndexPath:indexPath];
    return cell;
}

#pragma mark - Ask Us Options

- (NSString *)titleTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *titleText;
    switch (indexPath.row) {
        case AskUsOptionAskUs:
            titleText = @"Ask Us!";
            break;
        case AskUsOptionConsultation:
            titleText = @"Make a research consultation appointment";
            break;
        case AskUsOptionGeneral:
            titleText = @"General Help";
        default:
            break;
    }
    return titleText;
}

- (NSString *)detailTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *detailText;
    if (indexPath.row == AskUsOptionGeneral) {
        detailText = @"617.324.2275";
    }
    return detailText;
}

- (UIView *)accessoryViewForIndexPath:(NSIndexPath *)indexPath
{
    UIView *accessoryView;
    switch (indexPath.row) {
        case AskUsOptionAskUs:
        case AskUsOptionConsultation:
            accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            break;
        case AskUsOptionGeneral:
            accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
        default:
            break;
    }
    return accessoryView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case AskUsOptionAskUs: {
            MITLibrariesAskUsFormSheetViewController *askUs = [[MITLibrariesAskUsFormSheetViewController alloc] initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:askUs animated:YES];
            // TODO: Open ask us controller
            break;
        }
        case AskUsOptionConsultation: {
            LibrariesAppointmentViewController *appointmentVC = [LibrariesAppointmentViewController new];
            [self.navigationController pushViewController:appointmentVC animated:YES];
            // TODO: Open Consultation Controller
            break;
        }
        case AskUsOptionGeneral: {
            NSURL *url = [NSURL URLWithString:@"tel://16173242275"];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static MITLibrariesAskUsHomeTableViewCell *cell;
    cell = [MITLibrariesAskUsHomeTableViewCell new];
    cell.textLabel.text = [self titleTextForIndexPath:indexPath];
    CGSize maxSize = CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX);
    CGSize titleSize = [cell.textLabel sizeThatFits:maxSize];
    cell.detailTextLabel.text = [self detailTextForIndexPath:indexPath];
    CGSize detailSize = [cell.detailTextLabel sizeThatFits:maxSize];
    return titleSize.height + detailSize.height + 30; // Padding
}

@end
