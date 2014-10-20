#import "MITLibrariesCitationsViewController.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesCitationCell.h"

static NSInteger const kItemHeaderSection = 0;

static NSString * const kItemHeaderCellIdentifier = @"kItemHeaderCellIdentifier";
static NSString * const kCitationCellIdentifier = @"kCitationCellIdentifier";

@interface MITLibrariesCitationsViewController () <UITableViewDataSource, UITableViewDelegate, MITLibrariesCitationCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation MITLibrariesCitationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Citations";
    self.tableView.delaysContentTouches = NO;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
    }
    
    [self registerCells];
}

- (void)registerCells
{
    UINib *librariesItemCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCell class]) bundle:nil];
    [self.tableView registerNib:librariesItemCellNib forCellReuseIdentifier:kItemHeaderCellIdentifier];
    
    UINib *citationCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesCitationCell class]) bundle:nil];
    [self.tableView registerNib:citationCellNib forCellReuseIdentifier:kCitationCellIdentifier];
}

- (void)doneButtonPressed
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - UITableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + self.worldcatItem.citations.count;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kItemHeaderSection) {
        MITLibrariesWorldcatItemCell *itemHeaderCell = [self.tableView dequeueReusableCellWithIdentifier:kItemHeaderCellIdentifier];
        [itemHeaderCell setContent:self.worldcatItem];
        return itemHeaderCell;
    } else {
        MITLibrariesCitationCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCitationCellIdentifier];
        [cell setContent:self.worldcatItem.citations[indexPath.section - 1]];
        cell.delegate = self;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kItemHeaderSection) {
        return [MITLibrariesWorldcatItemCell heightForContent:self.worldcatItem tableViewWidth:self.tableView.bounds.size.width];
    } else {
        return [MITLibrariesCitationCell heightForContent:self.worldcatItem.citations[indexPath.section - 1] tableViewWidth:self.tableView.bounds.size.width];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kItemHeaderSection) {
        return nil;
    } else {
        MITLibrariesCitation *citation = self.worldcatItem.citations[section - 1];
        return citation.name;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kItemHeaderSection) {
        return 0.0001f;
    } else {
        return 35;
    }
}

#pragma mark - MITLibrariesCitationCellDelegate

- (void)citationCellShareButtonPressed:(NSAttributedString *)shareString
{
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[shareString] applicationActivities:nil];
    [self.navigationController presentViewController:activityVC animated:YES completion:^{
        // Nothing necessary
    }];
}

@end
