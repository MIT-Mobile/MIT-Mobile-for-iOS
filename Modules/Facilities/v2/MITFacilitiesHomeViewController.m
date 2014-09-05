//
//  MITFacilitiesHomeViewController.m
//  MIT Mobile
//
//  Created by Yev Motov on 9/1/14.
//
//

#import "MITFacilitiesHomeViewController.h"
#import "UIKit+MITAdditions.h"
#import <MessageUI/MFMailComposeViewController.h>

typedef NS_ENUM(NSUInteger, MITFacilitiesFormFieldType) {
    MITFacilitiesFormFieldEmail = 0,
    MITFacilitiesFormFieldLocation,
    MITFacilitiesFormFieldRoom,
    MITFacilitiesFormFieldProblemType,
    MITFacilitiesFormFieldDescription
};

static NSString* const kFacilitiesEmailAddress = @"txtdof@mit.edu";
static NSString* const kFacilitiesPhoneNumber = @"(617) 253-4948";

@interface MITFacilitiesHomeViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *contactFacilitiesButton;

@property (nonatomic, assign) BOOL hasSelectedBuilding;

@end

@implementation MITFacilitiesHomeViewController

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
    // Do any additional setup after loading the view.
    
    self.hasSelectedBuilding = NO;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.contactFacilitiesButton addTarget:self action:@selector(contactFacilitiesAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions

- (void)contactFacilitiesAction:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:[NSString stringWithFormat:@"Call %@", kFacilitiesPhoneNumber]
                                                    otherButtonTitles:[NSString stringWithFormat:@"Email %@", kFacilitiesEmailAddress], nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex == actionSheet.cancelButtonIndex )
    {
        return;
    }
    
    if( buttonIndex == actionSheet.destructiveButtonIndex )
    {
        // call
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://1%@",kFacilitiesPhoneNumber]];
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    else
    {
        // email
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
            [mailView setMailComposeDelegate:self];
            [mailView setSubject:@"Request from Building Services"];
            [mailView setToRecipients:[NSArray arrayWithObject:kFacilitiesEmailAddress]];
            [self presentViewController:mailView animated:YES completion:NULL];
        }
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:[UIColor mit_tintColor] forState:UIControlStateNormal];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - tableview stuff

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.row == [self lastRowIndex] )
    {
        return 62;
    }
    
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfFormFields];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if( indexPath.row == [self lastRowIndex] )
    {
        // action cell
        cell = [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
    }
    else
    {
        cell = [self tableView:tableView attributeCellForRowAtIndexPath:indexPath];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
    
    UILabel *actionLabel = (UILabel *)[cell viewWithTag:1];
    [actionLabel setText:@"Attach Photo"];
    [actionLabel setTextColor:[UIColor mit_tintColor]];
    
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 1000.);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView attributeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttributeCell" forIndexPath:indexPath];
    
    NSInteger row = indexPath.row;
    
    if( !self.hasSelectedBuilding && row >= MITFacilitiesFormFieldRoom )
    {
        row++;
    }
    
    BOOL hasDisclosureIndicator = NO;
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *subitleLabel = (UILabel *)[cell viewWithTag:2];
    
    switch (row) {
        case MITFacilitiesFormFieldEmail:
            titleLabel.text = @"email";
            break;
        case MITFacilitiesFormFieldLocation:
            titleLabel.text = @"location";
            hasDisclosureIndicator = YES;
            break;
        case MITFacilitiesFormFieldRoom:
            titleLabel.text = @"room";
            hasDisclosureIndicator = YES;
            break;
        case MITFacilitiesFormFieldProblemType:
            titleLabel.text = @"problem type";
            hasDisclosureIndicator = YES;
            break;
        case MITFacilitiesFormFieldDescription:
            titleLabel.text = @"description";
            break;
    }
    
    subitleLabel.text = @"";
    titleLabel.textColor = [UIColor mit_tintColor];
    titleLabel.font = [UIFont systemFontOfSize:14];
    
    cell.separatorInset = UIEdgeInsetsMake(0, 7., 0, 0);
    
    if( hasDisclosureIndicator )
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - helpers

- (NSInteger)numberOfFormFields
{
    NSInteger numberOfRows = self.hasSelectedBuilding ? 6 : 5;
    
    return numberOfRows;
}
       
       
- (NSInteger)lastRowIndex
{
    return [self numberOfFormFields] - 1;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
