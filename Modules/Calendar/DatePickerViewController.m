#import "DatePickerViewController.h"


@implementation DatePickerViewController

@synthesize delegate, date = _date;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    if (!self.date) {
        self.date = [NSDate date];
    }
    
    UIControl *scrim = [[UIControl alloc] initWithFrame:self.view.frame];
    scrim.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    [scrim addTarget:self.delegate action:@selector(datePickerViewControllerDidCancel:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:scrim];
    [scrim release];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    navBar.barStyle = UIBarStyleBlack;
    
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Jump to a Date"];
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Go" style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonPressed:)];
    navItem.rightBarButtonItem = doneButton;
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonPressed:)];
    navItem.leftBarButtonItem = cancelButton;
    
    [navBar pushNavigationItem:navItem animated:NO];
    
    [self.view addSubview:navBar];
    
    datePicker = [[UIDatePicker alloc] init];
    datePicker.frame = CGRectMake(0.0, self.view.frame.size.height - datePicker.frame.size.height, datePicker.frame.size.width, datePicker.frame.size.height);
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.date = self.date;
    datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:2 * 366 * 24 * 3600];
    datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-10 * 366 * 24 * 3600];
    [datePicker addTarget:self.delegate action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    
    [navItem release];
    [navBar release];
}

- (void)navBarButtonPressed:(id)sender
{
    if (sender == doneButton) {
        [self.delegate datePickerViewController:self didSelectDate:datePicker.date];
    } else if (sender == cancelButton) {
        [self.delegate datePickerViewControllerDidCancel:self];
    }
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [_date release];
    [datePicker release];
    [doneButton release];
    [cancelButton release];
    
    [super dealloc];
}


@end
