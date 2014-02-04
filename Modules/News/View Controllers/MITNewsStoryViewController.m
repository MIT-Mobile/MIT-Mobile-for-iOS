#import "MITNewsStoryViewController.h"
#import "MITNewsStory.h"

@interface MITNewsStoryViewController ()

@end

@implementation MITNewsStoryViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)htmlBody
{
    NSURL *templateURL = [[NSBundle mainBundle] URLForResource:@"news/news_story_template" withExtension:@"html"];
    
    NSError *error = nil;
    NSMutableString *templateString = [NSMutableString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
    NSAssert(templateString, @"failed to load News story HTML template");
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, y"];
    NSString *postDate = [dateFormatter stringFromDate:self.story.publishedAt];
    
    NSArray *templateBindings = @[@{@"__TITLE__": self.story.title},
                                  @{@"__AUTHOR__": self.story.author},
                                  @{@"__DATE__": postDate},
                                  @{@"__DEK__": self.story.dek},
                                  @{@"__BODY__": self.story.body},
                                  @{@"__GALLERY_COUNT__": @([self.story.galleryImages count])},
                                  @{@"__BOOKMARKED__": @""},
                                  @{@"__THUMBNAIL_URL__": @""},
                                  @{@"__THUMBNAIL_WIDTH__": @""},
                                  @{@"__THUMBNAIL_HEIGHT__": @""}];
    
    [templateBindings enumerateObjectsUsingBlock:^(NSDictionary *bindings, NSUInteger idx, BOOL *stop) {
        [bindings enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSString class]]) {
                [templateString replaceOccurrencesOfString:key
                                                withString:(NSString*)value
                                                   options:0
                                                     range:NSMakeRange(0, [templateString length])];
            } else if ([value respondsToSelector:@selector(stringValue)]) {
                [templateString replaceOccurrencesOfString:key
                                                withString:[value stringValue]
                                                   options:0
                                                     range:NSMakeRange(0, [templateString length])];
            } else if ([value isKindOfClass:[NSNull class]]) {
                
            }
        }];
    }];
    
    return templateString;
}

@end
