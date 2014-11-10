#import "MITToursHTMLTemplateInjector.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursStop.h"

static NSString *const kMITToursHTMLTemplateFilePath = @"tours/tours_directions_template.html";

@implementation MITToursHTMLTemplateInjector

+ (NSString *)templatedHTMLForDirectionsToStop:(MITToursDirectionsToStop *)directionsToStop viewWidth:(CGFloat)viewWidth
{
    NSMutableString *templatedHtml = [[NSMutableString alloc] initWithString:[MITToursHTMLTemplateInjector templateHTMLString]];
    
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", viewWidth];
    [templatedHtml replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__TITLE__" withString:directionsToStop.title options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__BODY__" withString:directionsToStop.bodyHTML options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
       
    return templatedHtml;
}

+ (NSString *)templatedHTMLForSideTripStop:(MITToursStop *)sideTripStop fromMainLoopStop:(MITToursStop *)mainLoopStop viewWidth:(CGFloat)viewWidth
{
    NSString *titleString = [NSString stringWithFormat:@"Directions from %@ to %@", mainLoopStop.title, sideTripStop.title];
    
    NSMutableString *templatedHtml = [[NSMutableString alloc] initWithString:[MITToursHTMLTemplateInjector templateHTMLString]];
   
    NSString *maxWidth = [NSString stringWithFormat:@"%.0f", viewWidth];
    [templatedHtml replaceOccurrencesOfString:@"__WIDTH__" withString:maxWidth options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__TITLE__" withString:titleString options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    [templatedHtml replaceOccurrencesOfString:@"__BODY__" withString:@"Directions are not availiable for Side Trips" options:NSLiteralSearch range:NSMakeRange(0, [templatedHtml length])];
    
    return templatedHtml;
}

+ (NSString *)templateHTMLString
{
    static NSString *template;
    if (!template) {
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
        NSURL *fileURL = [NSURL URLWithString:kMITToursHTMLTemplateFilePath relativeToURL:baseURL];
        
        template = [[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    }
    
    return template;
}

@end
