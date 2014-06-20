//
//  MITEmergencyContactsTableViewController.m
//  MIT Mobile
//
//  Created by Yev Motov on 6/18/14.
//
//

#import "MITEmergencyContactsTableViewController.h"
#import "EmergencyData.h"

@interface MITEmergencyContactsTableViewController ()

@property (nonatomic, copy) NSArray *emergencyContacts;
@property (nonatomic, strong) UITapGestureRecognizer *tapOutsideGesture;

@end

@implementation MITEmergencyContactsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = @"All Emergency Contacts";
    
    self.emergencyContacts = [[EmergencyData sharedData] allPhoneNumbers];
    
    if ( !self.emergencyContacts )
    {
        [[EmergencyData sharedData] reloadContacts];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tapOutsideGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOutsideDetected:)];
    [self.tapOutsideGesture setCancelsTouchesInView:NO];
    [self.navigationController.view.window addGestureRecognizer:self.tapOutsideGesture];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.view.window removeGestureRecognizer:self.tapOutsideGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.emergencyContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MITEmergencyContactTableCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSManagedObject *contactInfo = self.emergencyContacts[indexPath.row];
    
    UILabel *emergencyName = (UILabel *)[cell viewWithTag:1];
    UILabel *emergencyPhone = (UILabel *)[cell viewWithTag:2];
    UILabel *emergencySubtitle = (UILabel *)[cell viewWithTag:3];
    
    emergencyName.text = [contactInfo valueForKey:@"Title"];
    emergencyPhone.text = [contactInfo valueForKey:@"phone"];
    emergencySubtitle.text = [contactInfo valueForKey:@"summary"];
    
    BOOL isHidden = !emergencySubtitle.text || [emergencySubtitle.text length] == 0;
    [self setView:emergencySubtitle hidden:isHidden withinContentView:cell.contentView];
    
    return cell;
}

- (void) setView:(UIView *)view hidden:(BOOL)isHidden withinContentView:(UIView *)contentView
{
    [view setHidden:isHidden];
    
    for (NSLayoutConstraint *con in contentView.constraints)
    {
        if (con.firstItem == view  && con.firstAttribute == NSLayoutAttributeTop) {
            con.constant = isHidden ? -9 : 0;
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MITEmergencyContactTableCell"];
    UILabel *emergencySubtitle = (UILabel *)[cell viewWithTag:3];
    
    NSManagedObject *contactInfo = self.emergencyContacts[indexPath.row];
    
    NSString *summary = [contactInfo valueForKey:@"summary"];
    CGSize size = [summary sizeWithAttributes: @{NSFontAttributeName:emergencySubtitle.font}];
    if( size.width > (CGRectGetWidth(emergencySubtitle.frame) - 100) )
    {
        return 76;
    }
    
    return 56;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - actions

- (void) tapOutsideDetected:(UITapGestureRecognizer *)tapGesture
{
    if (tapGesture.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    
    CGPoint location = [tapGesture locationInView:nil]; // passing nil gives us coordinates in the window
    
    if ( ![self.view pointInside:[self.view convertPoint:location fromView:self.navigationController.view.window] withEvent:nil])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
