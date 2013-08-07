#import "DatePickerViewController.h"

@interface DatePickerViewController ()
@property (nonatomic,weak) UIDatePicker *datePicker;
@property (nonatomic,weak) UIBarButtonItem *cancelButton;
@property (nonatomic,weak) UIBarButtonItem *doneButton;
@end

@implementation DatePickerViewController

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
    
    UIBarButtonItem *doneButon = [[UIBarButtonItem alloc] initWithTitle:@"Go"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(navBarButtonPressed:)];
    navItem.rightBarButtonItem = doneButon;
    self.doneButton = doneButon;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(navBarButtonPressed:)];
    navItem.leftBarButtonItem = cancelButton;
    self.cancelButton = cancelButton;
    
    [navBar pushNavigationItem:navItem animated:NO];
    
    [self.view addSubview:navBar];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.frame = CGRectMake(0.0,
                                   self.view.frame.size.height - datePicker.frame.size.height,
                                   datePicker.frame.size.width,
                                   datePicker.frame.size.height);
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.date = self.date;
    datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:2 * 366 * 24 * 3600];
    datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-10 * 366 * 24 * 3600];
    [datePicker addTarget:self.delegate
                   action:@selector(datePickerValueChanged:)
         forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    self.datePicker = datePicker;
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
