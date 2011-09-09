#import "LibraryEmailFormViewController.h"
#import "LibrariesModule.h"
#import "MobileRequestOperation.h"


@implementation LibraryFormElement
@synthesize key;
@synthesize displayLabel;
@synthesize displayLabelSubtitle;
@synthesize required;
@synthesize onChangeJavaScript;

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel displayLabelSubtitle:(NSString *)aDisplayLabelSubtitle required:(BOOL)isRequired {
    self = [super init];
    if (self) {
        self.key = aKey;
        self.displayLabel = aDisplayLabel;
        self.displayLabelSubtitle = aDisplayLabelSubtitle;
        self.required = isRequired;
        self.onChangeJavaScript = nil;
    }
    return self;
}
- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired {
    return [self initWithKey:aKey displayLabel:aDisplayLabel displayLabelSubtitle:nil required:isRequired];
}

- (void)dealloc {
    self.key = nil;
    self.displayLabel = nil;
    self.onChangeJavaScript = nil;
    [super dealloc];
}

- (NSString *)labelHtml {
    NSString *requiredStar = @"";
    if (self.required) {
        requiredStar = @"<span class=\"required\">*</span>";
    } 
    
    NSString *labelSubtitleString = @"";
    if (self.displayLabelSubtitle) {
        labelSubtitleString = [NSString stringWithFormat:@"<br /><span class=\"smallprint\">%@</span>", self.displayLabelSubtitle];
    }
    
    return [NSString stringWithFormat:
            @"<h3><label for=\"%@\">%@ %@%@</label></h3><p id=\"warning-%@\" class=\"default\">MISSING!</p>", 
            self.key, self.displayLabel, requiredStar, labelSubtitleString,  self.key];
}

- (NSString *)formHtml {
    NSAssert(NO, @"Need to override method formElement");
    return nil;
}

@end

@implementation MenuLibraryFormElement
@synthesize placeHolder;
@synthesize options;
@synthesize displayOptions;

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues {
    self = [super initWithKey:aKey displayLabel:aDisplayLabel required:isRequired];
    if (self) {
        self.options = theValues;
        self.displayOptions = theValues;
    }
    return self;
}

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues placeHolder:(NSString *)aPlaceHolder; {
    self = [self initWithKey:aKey displayLabel:aDisplayLabel required:isRequired values:theValues];
    if (self) {
        self.placeHolder = aPlaceHolder;
    }
    return self;
}

- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues displayValues:(NSArray *)theDisplayValues placeHolder:(NSString *)aPlaceHolder {
    
    self = [self initWithKey:aKey displayLabel:aDisplayLabel required:isRequired values:theValues placeHolder:aPlaceHolder];
    if (self) {
        NSAssert((theValues.count == theDisplayValues.count), @"values count does not match displayValues count");
        self.displayOptions = theDisplayValues;
    }
    return self;
}

- (void)dealloc {
    self.options = nil;
    [super dealloc];
}

- (NSString *)formHtml {
    NSString *defaultDisplayValue = @"";
    if (self.placeHolder) {
        defaultDisplayValue = self.placeHolder;
    }
    NSString *optionsHtml = [NSString stringWithFormat:@"<option value=\"\">%@</option>", defaultDisplayValue];
    for (NSInteger index=0; index < self.options.count; index++) {
        optionsHtml = [optionsHtml stringByAppendingFormat:@"<option value=\"%@\">%@</option>", [self.options objectAtIndex:index], [self.displayOptions objectAtIndex:index]];
    }
    
    NSString *onChangeJavaScriptString = @"";
    if (self.onChangeJavaScript) {
        onChangeJavaScriptString = [NSString stringWithFormat:@"onchange=\"%@\"", self.onChangeJavaScript];
    }
    return [NSString stringWithFormat:@"<p><select id=\"%@\" name=\"%@\" %@ >%@</select></p>", self.key, self.key, onChangeJavaScriptString, optionsHtml];
}
 
@end

@implementation RadioLibraryFormElement
@synthesize options;
@synthesize displayOptions;


- (id)initWithKey:(NSString *)aKey displayLabel:(NSString *)aDisplayLabel required:(BOOL)isRequired values:(NSArray *)theValues displayValues:(NSArray *)theDisplayValues {
    
    self = [self initWithKey:aKey displayLabel:aDisplayLabel required:isRequired];
    if (self) {
        NSAssert((theValues.count == theDisplayValues.count), @"values count does not match displayValues count");
        self.options = theValues;
        self.displayOptions = theDisplayValues;
    }
    return self;
}

- (void)dealloc {
    self.options = nil;
    self.displayOptions = nil;
    [super dealloc];
}

- (NSString *)formHtml {
    NSString *optionsHtml = @"";
    for (NSInteger index=0; index < self.options.count; index++) {
        optionsHtml = [optionsHtml stringByAppendingFormat:@"<input type=\"radio\" name=\"%@\" value=\"%@\" />%@",
                       self.key, [self.options objectAtIndex:index], [self.displayOptions objectAtIndex:index]];
    }
    return [NSString stringWithFormat:@"<p>%@</p>", optionsHtml];
}

@end

@implementation TextLibraryFormElement

- (NSString *)formHtml {
    return [NSString stringWithFormat:@"<p><input type=\"text\" name=\"%@\" id=\"%@\" style=\"width:94%\"></p>", self.key, self.key];
}

@end

@implementation TextAreaLibraryFormElement

- (NSString *)formHtml {
    return [NSString stringWithFormat:@"<textarea rows=\"8\" name=\"%@\" id=\"%@\" style=\"width:97%\"></textarea>", self.key, self.key];
}

@end

@implementation LibraryFormElementGroup
@synthesize name;
@synthesize hidden;

+ (LibraryFormElementGroup *)groupForName:(NSString *)name elements:(NSArray *)elements {
    return [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
}

+ (LibraryFormElementGroup *)hiddenGroupForName:(NSString *)name elements:(NSArray *)elements {
    LibraryFormElementGroup *group = [[[LibraryFormElementGroup alloc] initWithName:name formElements:elements] autorelease];
    group.hidden = YES;
    return group;
}

- (id)initWithName:(NSString *)aName formElements:(NSArray *)theFormElements {
    self = [super init];
    if (self) {
        formElements = [theFormElements retain];
        self.name = aName;
    }
    return self;
}

- (void)dealloc {
    [formElements release];
    self.name = nil;
    [super dealloc];
}
    
- (NSString *)formHtml {
    NSString *elementsHtml = @"";
    for(LibraryFormElement *formElement in formElements) {
        elementsHtml = [elementsHtml stringByAppendingString:[formElement labelHtml]];
        elementsHtml = [elementsHtml stringByAppendingString:[formElement formHtml]];
    }
    NSString *hiddenString = @"";
    if (self.hidden) {
        hiddenString = @"style=\"display:none;\"";
    }
    return [NSString stringWithFormat:@"<fieldset id=\"%@\" %@>%@</fieldset>", self.name, hiddenString, elementsHtml];
}
    
- (BOOL)valueRequiredForKey:(NSString *)key {
    for(LibraryFormElement *formElement in formElements) {
        if ([key isEqualToString:formElement.key]) {
            return formElement.required;
        }
    }
    
    [NSException raise:@"key not found in form" format:@"%@ not found in group", key];
    return NO;
}

- (NSArray *)keys {
    NSMutableArray *keys = [NSMutableArray array];
    for(LibraryFormElement *formElement in formElements) {
        [keys addObject:formElement.key];
    }
    return keys;
}

@end

@interface LibraryEmailFormViewController (Private)
- (void)submitForm:(NSDictionary *)parameters;
@end

@implementation LibraryEmailFormViewController
@synthesize webView;
@synthesize loadingView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *formHtml = @"";
    for (LibraryFormElementGroup *formGroup in [self formGroups]) {
        formHtml = [formHtml stringByAppendingString:[formGroup formHtml]];
    }
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"libraries/libraries_form.html" relativeToURL:baseURL];
    NSError *error;
    NSMutableString *html = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!html) {
        ELog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
    }
    [html replaceOccurrencesOfString:@"__FORM_ELEMENTS__" withString:formHtml options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.webView.delegate = self;
    [self.webView loadHTMLString:html baseURL:nil];
    [self.view addSubview:self.webView];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.loadingView = nil;
    self.webView.delegate = nil;
    self.webView = nil;
}

- (void)dealloc {
    self.loadingView = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSArray *)formGroups {
    NSAssert(NO, @"Need to override method formGroups");
    return nil;
}

- (NSString *)command {
    NSAssert(NO, @"Need to override method command");
    return nil;  
}

- (NSDictionary *)parameters:(NSDictionary *)parameters {
    NSAssert(NO, @"Need to override method parameters:");
    return nil;   
}

- (NSString *)getFormValueForKey:(NSString *)key {
    NSString *value = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"formValue(\"%@\")", key]];
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)markValueAsPresentForKey:(NSString *)key {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"formValuePresent(\"%@\")", key]];
}

- (void)markValueAsMissingForKey:(NSString *)key {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"formValueMissing(\"%@\")", key]];
}

- (BOOL)populateFormValues:(NSMutableDictionary *)formValues {
    BOOL allRequiredFieldsPresent = YES;
    for (LibraryFormElementGroup *formGroup in [self formGroups]) {
        for (NSString *key in [formGroup keys]) {
            NSString *value = [self getFormValueForKey:key];
            
            if ([formGroup valueRequiredForKey:key]) {
                if ([value length]) {
                    [self markValueAsPresentForKey:key];
                } else {
                    [self markValueAsMissingForKey:key];
                    allRequiredFieldsPresent = NO;
                }
            }
            [formValues setObject:value forKey:key];
            
        }
    }
    return allRequiredFieldsPresent;
}

#pragma mark - UIWebView delegate

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if ([self populateFormValues:params]) {
            [self submitForm:params];
        }
        return NO;
    }
    return YES;
}

- (void)showErrorSubmittingForm {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Error submitting form" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void)submitForm:(NSDictionary *)parameters {
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:LibrariesTag
                                                                              command:[self command]
                                                                           parameters:parameters] autorelease];
    
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        [self.loadingView removeFromSuperview];
        
        if (error) {
            NSLog(@"Request failed with error: %@",[error localizedDescription]);
            [self showErrorSubmittingForm];
        } else {
            NSDictionary *jsonDict = jsonResult;
            BOOL success = [(NSNumber *)[jsonDict objectForKey:@"success"] boolValue];
            if (success) {
            
                NSDictionary *resultsDict = [jsonDict objectForKey:@"results"];
                NSString *text = [NSString stringWithFormat:@"%@\n\n%@", [resultsDict objectForKey:@"thank_you_text"], [resultsDict objectForKey:@"contents"]];
                UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
                textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                textView.text = text;
                [self.view addSubview:textView];
                [textView release];
            } else {
                [self showErrorSubmittingForm];
            }
        }
    };

    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    [librariesModule.requestQueue addOperation:request];
    
    // show a loading indicator
    if (!self.loadingView) {
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds] autorelease];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    [self.loadingView removeFromSuperview];
    self.loadingView.frame = self.view.bounds;
    [self.view addSubview:self.loadingView];
}

- (LibraryFormElement *)statusMenuFormElement {
    return             
        [[[MenuLibraryFormElement alloc] initWithKey:@"status" 
                                        displayLabel:@"Your status" 
                                            required:YES
                                              values:[NSArray arrayWithObjects:
                                                      @"UG",
                                                      @"GRAD",
                                                      @"FAC",
                                                      @"RS",
                                                      @"STAFF",
                                                      @"VS",
                                                      nil] 
                                       displayValues:[NSArray arrayWithObjects:
                                                      @"MIT Undergrad Student",
                                                      @"MIT Grad Student",
                                                      @"MIT Faculty",
                                                      @"MIT Research Staff",
                                                      @"MIT Staff",
                                                      @"MIT Visitor",
                                                      nil] 
                                         placeHolder:@"Your Status"] autorelease];
}
@end
