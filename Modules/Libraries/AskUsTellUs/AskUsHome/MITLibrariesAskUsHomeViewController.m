#import "MITLibrariesAskUsHomeViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITLibrariesAskUsFormSheetViewController.h"
#import "MITLibrariesConsultationFormSheetViewController.h"
#import "MITLibrariesTellUsFormSheetViewController.h"
#import "MITTelephoneHandler.h"

static NSString * const MITLibrariesAskUsHomeViewControllerCellIdentifier = @"MITLibrariesAskUsHomeViewControllerCellIdentifier";
static CGFloat const MITLibrariesAskUsHomeDetailLabelPadding = 6.0;
static CGFloat const MITLibrariesAskUsHomeCellPadding = 38.0;

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
- (void)layoutSubviews {
    [super layoutSubviews];
    CGPoint center = self.detailTextLabel.center;
    center.y += MITLibrariesAskUsHomeDetailLabelPadding;
    // Subtitle seems to be off by 2pts.  This lines up much better.
    center.x += 2.0;
    self.detailTextLabel.center = center;
}
@end

@interface MITLibrariesAskUsHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *askUsOptionsTableView;
@end

@implementation MITLibrariesAskUsHomeViewController

@synthesize availableAskUsOptions = _availableAskUsOptions;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    if (!self.title || self.title.length == 0) {
        self.title = @"Ask Us";
    }
    
    // Needs to be set explicitly for popover controller issues
    self.askUsOptionsTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
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
    return self.availableAskUsOptions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = self.availableAskUsOptions[section];
    return sectionData.count;;
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

- (NSInteger)askUsOptionForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *section = self.availableAskUsOptions[indexPath.section];
    NSInteger enumValue = [section[indexPath.row] integerValue];
    return enumValue;
}

- (NSString *)titleTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *titleText;
    switch ([self askUsOptionForIndexPath:indexPath]) {
        case MITLibrariesAskUsOptionAskUs:
            titleText = @"Ask Us";
            break;
        case MITLibrariesAskUsOptionConsultation:
            titleText = @"Make a research consultation appointment";
            break;
        case MITLibrariesAskUsOptionTellUs:
            titleText = @"Tell Us";
            break;
        case MITLibrariesAskUsOptionGeneral:
            titleText = @"General Help";
            break;
        default:
            break;
    }
    return titleText;
}

- (NSString *)detailTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *detailText;
    if ([self askUsOptionForIndexPath:indexPath] == MITLibrariesAskUsOptionGeneral) {
        detailText = @"617.324.2275";
    }
    return detailText;
}

- (UIView *)accessoryViewForIndexPath:(NSIndexPath *)indexPath
{
    UIView *accessoryView;
    switch ([self askUsOptionForIndexPath:indexPath]) {
        case MITLibrariesAskUsOptionAskUs:
        case MITLibrariesAskUsOptionTellUs:
        case MITLibrariesAskUsOptionConsultation:
            accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
            break;
        case MITLibrariesAskUsOptionGeneral:
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
    
    MITLibrariesAskUsOption selectedOption = [self askUsOptionForIndexPath:indexPath];
    if (!self.delegate) {
        switch (selectedOption) {
            case MITLibrariesAskUsOptionAskUs: {
                MITLibrariesAskUsFormSheetViewController *askUs = [MITLibrariesAskUsFormSheetViewController  new];
                [self.navigationController pushViewController:askUs animated:YES];
                break;
            }
            case MITLibrariesAskUsOptionConsultation: {
                MITLibrariesConsultationFormSheetViewController *appointmentVC = [MITLibrariesConsultationFormSheetViewController new];
                [self.navigationController pushViewController:appointmentVC animated:YES];
                break;
            }
            case MITLibrariesAskUsOptionTellUs: {
                MITLibrariesTellUsFormSheetViewController *tellUsVC = [MITLibrariesTellUsFormSheetViewController new];
                [self.navigationController pushViewController:tellUsVC animated:YES];
                break;
            }
            case MITLibrariesAskUsOptionGeneral: {
                [MITTelephoneHandler attemptToCallPhoneNumber:@"16173242275"];
                break;
            }
            default:
                break;
        }
    }
    else {
        [self.delegate librariesAskUsHomeViewController:self didSelectAskUsOption:selectedOption];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static MITLibrariesAskUsHomeTableViewCell *cell;
    if (!cell) cell = [MITLibrariesAskUsHomeTableViewCell new];
    cell.textLabel.text = [self titleTextForIndexPath:indexPath];
    CGSize maxSize = CGSizeMake(CGRectGetWidth(tableView.bounds), CGFLOAT_MAX);
    CGSize titleSize = [cell.textLabel sizeThatFits:maxSize];
    NSString *detailText = [self detailTextForIndexPath:indexPath];
    CGFloat detailHeight = 0;
    if (detailText) {
        cell.detailTextLabel.text = [self detailTextForIndexPath:indexPath];
        CGSize detailSize = [cell.detailTextLabel sizeThatFits:maxSize];
        detailHeight += detailSize.height;
        detailHeight += MITLibrariesAskUsHomeDetailLabelPadding;
    }
    return titleSize.height + detailHeight + MITLibrariesAskUsHomeCellPadding;
}

#pragma mark - Getters | Setters

- (NSArray *)availableAskUsOptions {
    if (!_availableAskUsOptions) {
        NSArray *topGroup = @[@(MITLibrariesAskUsOptionAskUs), @(MITLibrariesAskUsOptionConsultation)];
        NSArray *bottomGroup = @[@(MITLibrariesAskUsOptionGeneral)];
        _availableAskUsOptions = @[topGroup, bottomGroup];
    }
    return _availableAskUsOptions;
}
- (void)setAvailableAskUsOptions:(NSArray *)availableOptions
{
    _availableAskUsOptions = availableOptions;
    [self.askUsOptionsTableView reloadData];
}

@end
