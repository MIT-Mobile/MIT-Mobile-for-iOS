#import "DatePickerViewController.h"


@implementation DatePickerViewController
{
    UIDatePicker *_datePicker;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
}

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
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    navBar.barStyle = UIBarStyleBlack;
    
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Jump to a Date"];
    
    _doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Go" style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonPressed:)];
    navItem.rightBarButtonItem = _doneButton;
    
    _cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(navBarButtonPressed:)];
    navItem.leftBarButtonItem = _cancelButton;
    
    [navBar pushNavigationItem:navItem animated:NO];
    
    [self.view addSubview:navBar];
    
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.frame = CGRectMake(0.0,
                                   self.view.frame.size.height - _datePicker.frame.size.height,
                                   _datePicker.frame.size.width,
                                   _datePicker.frame.size.height);
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.date = self.date;
    _datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:2 * 366 * 24 * 3600];
    _datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-10 * 366 * 24 * 3600];
    [_datePicker addTarget:self.delegate action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_datePicker];
}

- (void)navBarButtonPressed:(id)sender
{
    if (sender == _datePicker) {
        [self.delegate datePickerViewController:self didSelectDate:_datePicker.date];
    } else if (sender == _cancelButton) {
        [self.delegate datePickerViewControllerDidCancel:self];
    }
}

@end
