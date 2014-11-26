#import "MITToursHomeViewControllerPad.h"
#import "MITToursSelfGuidedTourCell.h"
#import "MITToursInfoCollectionCell.h"
#import "MITToursWebservices.h"
#import "MITToursTour.h"
#import "MITToursAboutMITViewController.h"
#import "MITToursLinksTableViewController.h"
#import "MITToursSelfGuidedTourContainerControllerPad.h"

static NSString *const kMITSelfGuidedTourCell = @"MITToursSelfGuidedTourCell";
static NSString *const kMITToursInfoCollectionCell = @"MITToursInfoCollectionCell";

@interface MITToursHomeViewControllerPad () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) MITToursTour *selfGuidedTour;

@property (nonatomic, strong) UIPopoverController *linksPopover;

@end

@implementation MITToursHomeViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Tours";
    
    [self setupNavBar];
    [self setupTableView];
    [self setupCollectionView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
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

- (void)setupNavBar
{
    UIBarButtonItem *linksButton = [[UIBarButtonItem alloc] initWithTitle:@"Links" style:UIBarButtonItemStylePlain target:self action:@selector(linksButtonPressed:)];
    self.navigationItem.rightBarButtonItem = linksButton;
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITSelfGuidedTourCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITSelfGuidedTourCell];
}

- (void)setupCollectionView
{
    UINib *cellNib = [UINib nibWithNibName:kMITToursInfoCollectionCell bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:kMITToursInfoCollectionCell];
}

#pragma mark - TableView Datasource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 289.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITToursSelfGuidedTourCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITSelfGuidedTourCell];
    
    if (self.selfGuidedTour) {
        [cell setTour:self.selfGuidedTour];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.selfGuidedTour) {
        MITToursSelfGuidedTourContainerControllerPad *containerController = [[MITToursSelfGuidedTourContainerControllerPad alloc] init];
        containerController.selfGuidedTour = self.selfGuidedTour;
        [self.navigationController pushViewController:containerController animated:YES];
    }
}

#pragma mark - CollectionView Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITToursInfoCollectionCell sizeForInfoText:[self infoTextForIndexPath:indexPath] buttonText:[self buttonTextForIndexPath:indexPath]];
}

#pragma mark - CollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITToursInfoCollectionCell *cell = [self blankInfoCellForIndexPath:indexPath];
    [cell configureForInfoText:[self infoTextForIndexPath:indexPath] buttonText:[self buttonTextForIndexPath:indexPath]];
    if (indexPath.row == 0) {
        [cell.infoButton addTarget:self action:@selector(moreAboutToursPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [cell.infoButton addTarget:self action:@selector(moreAboutMITPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

- (void)updateDisplayedTour
{
    [self.tableView reloadData];
}

- (NSString *)infoTextForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return [MITToursWebservices aboutGuidedToursText];
    }
    else {
        return [MITToursWebservices aboutMITText];
    }
}

- (NSString *)buttonTextForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return @"More about guided tours...";
    }
    else {
        return @"More about MIT...";
    }
}

- (MITToursInfoCollectionCell *)blankInfoCellForIndexPath:(NSIndexPath *)indexPath
{
    MITToursInfoCollectionCell *cell  = [self.collectionView dequeueReusableCellWithReuseIdentifier:kMITToursInfoCollectionCell forIndexPath:indexPath];
    
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
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:aboutVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissFormSheet)];
    aboutVC.navigationItem.rightBarButtonItem = doneButton;    
    
    [self presentViewController:navVC animated:YES completion:NULL];
}

- (void)dismissFormSheet
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[MITToursWebservices aboutMITURLString]]];
    }
}

- (void)linksButtonPressed:(id)sender
{
    [self.linksPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (UIPopoverController *)linksPopover
{
    if (!_linksPopover) {
        MITToursLinksTableViewController *linksVC = [[MITToursLinksTableViewController alloc] init];
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:linksVC];
        _linksPopover = [[UIPopoverController alloc] initWithContentViewController:navVC];
        [_linksPopover setPopoverContentSize:CGSizeMake(320, 132 + navVC.navigationBar.frame.size.height)];
    }
    return _linksPopover;
}

@end
