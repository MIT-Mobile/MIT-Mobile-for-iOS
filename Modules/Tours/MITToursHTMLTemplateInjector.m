#import "MITToursHTMLTemplateInjector.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursStop.h"

static NSString *const kMITToursHTMLTemplateFilePath = @"tours/tours_directions_template.html";
static NSString *const kMITToursHTMLDetailsTemplateFilePath = @"tours/tours_tour_detail_template.html";

@implementation MITToursHTMLTemplateInjector

+ (NSString *)templatedHTMLForDirectionsToStop:(MITToursDirectionsToStop *)directionsToStop viewWidth:(CGFloat)viewWidth
{
    NSMutableString *templatedHtml = [[NSMutableString alloc] initWithString:[MITToursHTMLTemplateInjector templateHTMLStringForTemplatePath:kMITToursHTMLTemplateFilePath]];
    
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", viewWidth];
    [templatedHtml replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__TITLE__" withString:directionsToStop.title options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__BODY__" withString:directionsToStop.bodyHTML options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
       
    return templatedHtml;
}

+ (NSString *)templatedHTMLForSideTripStop:(MITToursStop *)sideTripStop fromMainLoopStop:(MITToursStop *)mainLoopStop viewWidth:(CGFloat)viewWidth
{
    NSString *titleString = [NSString stringWithFormat:@"Directions from %@ to %@", mainLoopStop.title, sideTripStop.title];
    
    NSMutableString *templatedHtml = [[NSMutableString alloc] initWithString:[MITToursHTMLTemplateInjector templateHTMLStringForTemplatePath:kMITToursHTMLTemplateFilePath]];
   
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", viewWidth];
    [templatedHtml replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__TITLE__" withString:titleString options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__BODY__" withString:@"Step by step directions are not available for side trips." options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    
    return templatedHtml;
}

+ (NSString *)templatedHTMLForTourDetailsHTML:(NSString *)tourDetailsHTML viewWidth:(CGFloat)viewWidth
{
    NSMutableString *templatedHtml = [[NSMutableString alloc] initWithString:[MITToursHTMLTemplateInjector templateHTMLStringForTemplatePath:kMITToursHTMLDetailsTemplateFilePath]];
   
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", viewWidth];
    [templatedHtml replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__BODY__" withString:tourDetailsHTML options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];

    return templatedHtml;
}

+ (NSString *)templateHTMLStringForTemplatePath:(NSString *)templatePath
{
    static NSString *template;
    if (!template) {
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
        NSURL *fileURL = [NSURL URLWithString:templatePath relativeToURL:baseURL];
        
        template = [[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    }
    
    return template;
}

@end
