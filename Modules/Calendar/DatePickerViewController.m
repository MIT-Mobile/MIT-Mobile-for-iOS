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
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    UIControl *scrim = [[UIControl alloc] initWithFrame:self.view.frame];
    scrim.backgroundColor = [UIColor clearColor];
    [scrim addTarget:self.delegate action:@selector(datePickerViewControllerDidCancel:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:scrim];
    
    CGRect frame = CGRectMake(0.0, 20., self.view.frame.size.width, 44.0);
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0);
        self.view.backgroundColor = [UIColor blackColor];
    }
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:frame];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        navBar.barStyle = UIBarStyleDefault;
    } else {
        navBar.barStyle = UIBarStyleBlack;
    }
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Jump to a Date"];
    
    UIBarButtonItem *doneButon = [[UIBarButtonItem alloc] initWithTitle:@"Go"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(go:)];
    navItem.rightBarButtonItem = doneButon;
    self.doneButton = doneButon;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancel:)];
    navItem.leftBarButtonItem = cancelButton;
    self.cancelButton = cancelButton;
    
    [navBar pushNavigationItem:navItem animated:NO];
    
    [self.view addSubview:navBar];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.frame = CGRectIntegral(CGRectMake(0.0,
                                   (self.view.frame.size.height - datePicker.frame.size.height) / 2.0,
                                   datePicker.frame.size.width,
                                   datePicker.frame.size.height));
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.date = self.date;
    datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:2 * 366 * 24 * 3600];
    datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-10 * 366 * 24 * 3600];
    [self.view addSubview:datePicker];
    self.datePicker = datePicker;
}

- (void)go:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(datePickerViewController:didSelectDate:)]) {
        [self.delegate datePickerViewController:self didSelectDate:_datePicker.date];
    }}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(datePickerViewControllerDidCancel:)]) {
        [self.delegate datePickerViewControllerDidCancel:self];
    }
}

@end
