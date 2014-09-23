#import "MITLibrariesYourAccountViewController.h"

typedef NS_ENUM(NSInteger, MITLibrariesYourAccountSection) {
    MITLibrariesYourAccountSectionLoans = 0,
    MITLibrariesYourAccountSectionFines,
    MITLibrariesYourAccountSectionHolds
};

@interface MITLibrariesYourAccountViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign) MITLibrariesYourAccountSection currentSection;
@property (nonatomic, strong) UISegmentedControl *accountSectionSegmentedControl;

@end

@implementation MITLibrariesYourAccountViewController

#pragma mark - Init/Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupToolbar
{
    self.accountSectionSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Loans", @"Fines", @"Holds"]];
    [self.accountSectionSegmentedControl addTarget:self action:@selector(accountSectionSegmentedControlChanged) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.accountSectionSegmentedControl];
    self.toolbarItems = @[segmentedControlItem];
}

#pragma mark -

- (void)accountSectionSegmentedControlChanged
{
    switch (self.accountSectionSegmentedControl.selectedSegmentIndex) {
        case MITLibrariesYourAccountSectionLoans: {
            self.title = @"Loans";
            break;
        }
        case MITLibrariesYourAccountSectionFines: {
            self.title = @"Fines";
            break;
        }
        case MITLibrariesYourAccountSectionHolds: {
            self.title = @"Holds";
            break;
        }
    }
}

#pragma mark - Base TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (self.currentSection) {
        case MITLibrariesYourAccountSectionLoans: {
            
            break;
        }
        case MITLibrariesYourAccountSectionFines: {
            
            break;
        }
        case MITLibrariesYourAccountSectionHolds: {
            
            break;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.currentSection) {
        case MITLibrariesYourAccountSectionLoans: {
            
            break;
        }
        case MITLibrariesYourAccountSectionFines: {
            
            break;
        }
        case MITLibrariesYourAccountSectionHolds: {
            
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.currentSection) {
        case MITLibrariesYourAccountSectionLoans: {
            return [self cellForLoansAtIndexPath:indexPath];
            break;
        }
        case MITLibrariesYourAccountSectionFines: {
            return [self cellForFinesAtIndexPath:indexPath];
            break;
        }
        case MITLibrariesYourAccountSectionHolds: {
            return [self cellForHoldsAtIndexPath:indexPath];
            break;
        }
    }
}

#pragma mark - Loans Section TableView Methods

- (UITableViewCell *)cellForLoansAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Fines Section TableView Methods

- (UITableViewCell *)cellForFinesAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Holds Section TableView Methods

- (UITableViewCell *)cellForHoldsAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
