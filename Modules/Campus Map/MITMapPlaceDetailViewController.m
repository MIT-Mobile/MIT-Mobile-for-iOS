#import "MITMapPlaceDetailViewController.h"
#import "MITMapPlace.h"
#import "MITMapPlaceContentCell.h"
#import "MITMapPlacePhotoCell.h"
#import "MITMapPlaceNameCell.h"
#import "MITMapPlaceBottomButtonCell.h"
#import "MITMapModelController.h"
#import "MIT_MobileAppDelegate.h"

static NSString * const kMITMapPlaceContentCellNibName = @"MITMapPlaceContentCell";
static NSString * const kMITMapPlaceContentCellIdentifier = @"kMITMapPlaceContentCellIdentifier";

static NSString * const kMITMapPlaceNameCellNibName = @"MITMapPlaceNameCell";
static NSString * const kMITMapPlaceNameCellIdentifier = @"kMITMapPlaceNameCellIdentifier";

static NSString * const kMITMapPlacePhotoCellNibName = @"MITMapPlacePhotoCell";
static NSString * const kMITMapPlacePhotoCellIdentifier = @"kMITMapPlacePhotoCellIdentifier";

static NSString * const kMITMapPlaceBottomButtonCellNibName = @"MITMapPlaceBottomButtonCell";
static NSString * const kMITMapPlaceBottomButtonCellIdentifier = @"kMITMapPlaceBottomButtonCellIdentifier";

static NSInteger const kMITMapPlaceNameAndImageSection = 0;
static NSInteger const kMITMapPlaceNameRow = 0;
static NSInteger const kMITMapPlaceImageRow = 1;

static NSInteger const kMITMapPlaceContentsSection = 1;

static NSInteger const kMITMapPlaceBottomButtonsSection = 2;
static NSInteger const kMITMapPlaceBottomButtonAddToBookmarksRow = 0;
static NSInteger const kMITMapPlaceBottomButtonOpenInMapsRow = 1;
static NSInteger const kMITMapPlaceBottomButtonOpenInGoogleMapsRow = 2;

@interface MITMapPlaceDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MITMapPlaceContentCell *placeContentCell;
@property (strong, nonatomic) MITMapPlacePhotoCell *placePhotoCell;

@end

@implementation MITMapPlaceDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:kMITMapPlaceContentCellNibName bundle:nil] forCellReuseIdentifier:kMITMapPlaceContentCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITMapPlaceNameCellNibName bundle:nil] forCellReuseIdentifier:kMITMapPlaceNameCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITMapPlacePhotoCellNibName bundle:nil] forCellReuseIdentifier:kMITMapPlacePhotoCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITMapPlaceBottomButtonCellNibName bundle:nil] forCellReuseIdentifier:kMITMapPlaceBottomButtonCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods

- (void)bookmarksButtonPressed
{
    if (self.place.bookmark == nil) {
        [self addToBookmarks];
    } else {
        [self removeFromBookmarks];
    }
}

- (void)addToBookmarks
{
    [[MITMapModelController sharedController] bookmarkPlaces:@[self.place] completion:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        } else {
            [self.tableView reloadData];
        }
    }];
}

- (void)removeFromBookmarks
{
    [[MITMapModelController sharedController] removeBookmarkForPlace:self.place completion:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        } else {
            [self.tableView reloadData];
        }
    }];
}

- (void)openInMaps
{
    NSString *mapsUrlString = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@,%@", self.place.latitude, self.place.longitude];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsUrlString]];
    
}

- (void)openInGoogleMaps
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"comgooglemaps://"];
    [urlComponents setQuery:[NSString stringWithFormat:@"q=%@,%@", self.place.latitude, self.place.longitude]];
    [[UIApplication sharedApplication] openURL:[urlComponents URL]];
}

#pragma mark - Custom Cells

- (MITMapPlaceContentCell *)placeContentCell
{
    if (!_placeContentCell) {
        _placeContentCell = [[NSBundle mainBundle] loadNibNamed:kMITMapPlaceContentCellNibName owner:self options:nil][0];
    }
    return _placeContentCell;
}

- (MITMapPlacePhotoCell *)placePhotoCell
{
    if (!_placePhotoCell) {
        _placePhotoCell = [[NSBundle mainBundle] loadNibNamed:kMITMapPlacePhotoCellNibName owner:self options:nil][0];
    }
    return _placePhotoCell;
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITMapPlaceNameAndImageSection: {
            switch (indexPath.row) {
                case kMITMapPlaceNameRow: {
                    return 44;
                    break;
                }
                case kMITMapPlaceImageRow: {
                    return 161;
                    break;
                }
                default: {
                    return 0;
                }
            }
        }
        case kMITMapPlaceContentsSection: {
            [self.placeContentCell setPlaceContent:[[self.place.contents array] objectAtIndex:indexPath.row]];
            
            [self.placeContentCell setNeedsUpdateConstraints];
            [self.placeContentCell updateConstraintsIfNeeded];
            self.placeContentCell.bounds = CGRectMake(0, 0, self.tableView.bounds.size.width, self.placeContentCell.bounds.size.height);
            [self.placeContentCell setNeedsLayout];
            [self.placeContentCell layoutIfNeeded];
            
            CGFloat height = [self.placeContentCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            ++height;   // add pt for cell separator;
            return height;
            break;
        }
        case kMITMapPlaceBottomButtonsSection: {
            return 44;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITMapPlaceBottomButtonsSection: {
            switch (indexPath.row) {
                case kMITMapPlaceBottomButtonAddToBookmarksRow: {
                    [self addToBookmarks];
                    break;
                }
                case kMITMapPlaceBottomButtonOpenInMapsRow: {
                    [self openInMaps];
                    break;
                }
                case kMITMapPlaceBottomButtonOpenInGoogleMapsRow: {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
                        [self openInGoogleMaps];
                    }
                    break;
                }
                default: {
                    break;
                }
            }
        }
        default: {
            return;
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITMapPlaceNameAndImageSection: {
            return 2;
            break;
        }
        case kMITMapPlaceContentsSection: {
            return [self.place.contents array].count;
            break;
        }
        case kMITMapPlaceBottomButtonsSection: {
            return 3;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITMapPlaceNameAndImageSection: {
            switch (indexPath.row) {
                case kMITMapPlaceNameRow: {
                    MITMapPlaceNameCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapPlaceNameCellIdentifier];
                    cell.nameLabel.text = self.place.name;
                    cell.addressLabel.text = self.place.streetAddress;
                    return cell;
                }
                case kMITMapPlaceImageRow: {
                    MITMapPlacePhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapPlacePhotoCellIdentifier];
                    [cell setPlace:self.place];
                    [self.placeContentCell setNeedsUpdateConstraints];
                    [self.placeContentCell updateConstraintsIfNeeded];
                    return cell;
                }
                default: {
                    return [UITableViewCell new];
                }
            }
        }
        case kMITMapPlaceContentsSection: {
            MITMapPlaceContentCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapPlaceContentCellIdentifier];
            [cell setPlaceContent:[[self.place.contents array] objectAtIndex:indexPath.row]];
            [self.placeContentCell setNeedsUpdateConstraints];
            [self.placeContentCell updateConstraintsIfNeeded];
            return cell;
        }
        case kMITMapPlaceBottomButtonsSection: {
            MITMapPlaceBottomButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapPlaceBottomButtonCellIdentifier];
            
            switch (indexPath.row) {
                case kMITMapPlaceBottomButtonAddToBookmarksRow: {
                    if (self.place.bookmark == nil) {
                        [cell.button setTitle:@"Add to Bookmarks" forState:UIControlStateNormal];
                    } else {
                        [cell.button setTitle:@"Remove from Bookmarks" forState:UIControlStateNormal];
                    }
                    
                    [cell setTopSeparatorHidden:NO];
                    [cell setBottomSeparatorHidden:NO];
                    
                    break;
                }
                case kMITMapPlaceBottomButtonOpenInMapsRow: {
                    [cell.button setTitle:@"Open in Maps" forState:UIControlStateNormal];
                    [cell setTopSeparatorHidden:YES];
                    [cell setBottomSeparatorHidden:NO];
                    break;
                }
                case kMITMapPlaceBottomButtonOpenInGoogleMapsRow: {
                    [cell.button setTitle:@"Open in Google Maps" forState:UIControlStateNormal];
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
                        cell.button.enabled = YES;
                        cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    } else {
                        cell.button.enabled = NO;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                    [cell setTopSeparatorHidden:YES];
                    [cell setBottomSeparatorHidden:NO];
                    break;
                }
                default: {
                    [cell.button setTitle:@"" forState:UIControlStateNormal];
                    break;
                }
            }
            
            return cell;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kMITMapPlaceBottomButtonsSection: {
            return 10;
        }
        default: {
            return 0;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    switch (section) {
        case kMITMapPlaceBottomButtonsSection: {
            return 10;
        }
        default: {
            return 0;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kMITMapPlaceBottomButtonsSection: {
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
        }
        default: {
            return [UIView new];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    switch (section) {
        case kMITMapPlaceBottomButtonsSection: {
            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
        }
        default: {
            return [UIView new];
        }
    }
}

@end
