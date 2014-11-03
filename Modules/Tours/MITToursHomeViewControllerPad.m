#import "MITToursHomeViewControllerPad.h"
#import "MITToursSelfGuidedTourCell.h"
#import "MITToursInfoCollectionCell.h"
#import "MITToursWebservices.h"
#import "MITToursTour.h"
#import "MITToursAboutMITViewController.h"

static NSString *const kMITSelfGuidedTourCell = @"MITToursSelfGuidedTourCell";
static NSString *const kMITToursInfoCollectionCell = @"MITToursInfoCollectionCell";

@interface MITToursHomeViewControllerPad () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) MITToursTour *selfGuidedTour;

@end

@implementation MITToursHomeViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.coverImageView.image = [UIImage imageNamed:@"tours/tours_cover_image.jpg"];
    
    [self setupTableView];
    [self setupCollectionView];
    
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
    return self.selfGuidedTour ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selfGuidedTour ? 1 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 106.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITToursSelfGuidedTourCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITSelfGuidedTourCell];
    
    [cell setTour:self.selfGuidedTour];
    
    return cell;
}

// iOS 7 requires this to make the cell transparent for whatever reason
- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
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
    MITToursInfoCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kMITToursInfoCollectionCell forIndexPath:indexPath];
    [cell.infoButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    if (indexPath.row == 0) {
        return [self moreAboutToursCellForIndexPath:indexPath];
    }
    else {
        return [self moreAboutMITCellForIndexPath:indexPath];
    }
    
    return cell;
}

- (void)updateDisplayedTour
{
    [self.tableView reloadData];
}

- (UICollectionViewCell *)moreAboutToursCellForIndexPath:(NSIndexPath *)indexPath
{
    MITToursInfoCollectionCell *cell = [self blankInfoCellForIndexPath:indexPath];

    cell.infoTextLabel.text = [MITToursWebservices aboutGuidedToursText];
    [cell.infoButton setTitle:@"More about guided tours..." forState:UIControlStateNormal];
    [cell.infoButton addTarget:self action:@selector(moreAboutToursPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (UICollectionViewCell *)moreAboutMITCellForIndexPath:(NSIndexPath *)indexPath
{
    MITToursInfoCollectionCell *cell = [self blankInfoCellForIndexPath:indexPath];

    cell.infoTextLabel.text = [MITToursWebservices aboutMITText];
    [cell.infoButton setTitle:@"More about MIT..." forState:UIControlStateNormal];
    [cell.infoButton addTarget:self action:@selector(moreAboutMITPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
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

@end
