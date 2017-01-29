#import "MITScannerAdvancedMenuViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITBatchScanningCell.h"

@interface MITScannerAdvancedMenuViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@interface MITScannerAdvancedMenuViewController (BatchScanningCellHandler) <MITBatchScanningCellDelegate>

- (NSString *)descForMultipleScanSetting;
- (NSString *)descForSingleScanSetting;

@end

CGFloat const rowHeight = 100;

@implementation MITScannerAdvancedMenuViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSString *nibName = @"MITScannerAdvancedMenuViewController";
    if( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        nibName = @"MITScannerAdvancedMenuViewController_ipad";
    }
    
    self = [super initWithNibName:nibName bundle:nibBundleOrNil];
    if( self )
    {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MITBatchScanningCell" bundle:nil] forCellReuseIdentifier:@"batchScanningCell"];
    
    self.title = @"Advanced";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissMenu:)];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissMenu:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITBatchScanningCell *cell = [tableView dequeueReusableCellWithIdentifier:@"batchScanningCell" forIndexPath:indexPath];
    
    cell.delegate = self;
    
    BOOL doBatchScanning = [[NSUserDefaults standardUserDefaults] boolForKey:kBatchScanningSettingKey];
    [cell setBatchScanningToggleSwitch:doBatchScanning];
    
    NSString *settingDescText = doBatchScanning ? [self descForMultipleScanSetting] : [self descForSingleScanSetting];
    [cell updateSettingDescriptionWithText:settingDescText];
    
    return cell;
}

- (CGFloat)menuViewHeight
{
    return rowHeight;
}

@end

@implementation MITScannerAdvancedMenuViewController (BatchScanningCellHandler)

- (void)toggleSwitchDidChangeValue:(UISwitch *)toggleSwitch inCell:(MITBatchScanningCell *)cell
{
    NSString *settingDescText = toggleSwitch.isOn ? [self descForMultipleScanSetting] : [self descForSingleScanSetting];
    
    [cell updateSettingDescriptionWithText:settingDescText];
    
    [[NSUserDefaults standardUserDefaults] setBool:toggleSwitch.isOn forKey:kBatchScanningSettingKey];
}

- (NSString *)descForMultipleScanSetting
{
    return @"The device is set to scan multiple codes in quick succession.";
}

- (NSString *)descForSingleScanSetting
{
    return @"The device is set to scan one code at a time.";
}

@end


