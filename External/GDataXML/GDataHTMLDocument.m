#import "GDataHTMLDocument.h"

@interface GDataXMLDocument ()
- (void)addStringsCacheToDoc;
@end

@implementation GDataHTMLDocument
- (id)initWithHTMLString:(NSString *)str options:(unsigned int)mask error:(NSError **)error {
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    GDataHTMLDocument *doc = [self initWithData:data options:mask error:error];
    return doc;
}

- (id)initWithData:(NSData *)data options:(unsigned int)mask error:(NSError **)error {
    self = [super init];
    if (self) {
        
        const char *baseURL = NULL;
        const char *encoding = NULL;
        
        // NOTE: We are assuming [data length] fits into an int.
        xmlDoc_ = htmlReadMemory((const char*)[data bytes],
                                (int)[data length],
                                baseURL,
                                encoding,
                                mask); //
        if (xmlDoc_ == NULL) {
            if (error) {
                xmlErrorPtr xmlError = xmlGetLastError();
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithCString:xmlError->message
                                                                                               encoding:NSUTF8StringEncoding]
                                                                     forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:@"com.google.GDataXML"
                                             code:xmlError->code
                                         userInfo:userInfo];
            }
            [self release];
            return nil;
        } else {
            if (error) *error = NULL;
            
            [self addStringsCacheToDoc];
        }
    }
    
    return self;
}
@end
