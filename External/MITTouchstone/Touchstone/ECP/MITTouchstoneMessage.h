#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#import <Foundation/Foundation.h>


@interface MITTouchstoneMessage : NSObject
@property (nonatomic,readonly) xmlDocPtr document;
@property (nonatomic,readonly) xmlXPathContextPtr xpathContext;

@property (nonatomic,readonly,strong) NSError *error;

+ (NSDictionary*)defaultNamespaces;
+ (xmlXPathContextPtr)createXPathContextForDocument:(xmlDocPtr)document;

// Copies the xmlDoc using a recursive xmlCopyDoc() on initialization, caller is responsible
// for free() ing their original copy of the document.
- (instancetype)initWithData:(NSData*)xmlData;

- (BOOL)hasNextRequest;
- (NSURLRequest*)nextRequestWithURL:(NSURL*)url;

@end
