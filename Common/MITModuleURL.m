#import "MITModuleURL.h"
#import "MIT_MobileAppDelegate+ModuleList.h"

@implementation MITModuleURL
@synthesize path, query;

- (id) initWithTag:(NSString *)tag {
	return [self initWithTag:tag path:@"" query:nil];
}

- (id) initWithTag:(NSString *)tag path:(NSString *)aPath query:(NSString *)aQuery {
	self = [super init];
	if (self) {
		[self setPath:aPath query:aQuery];
		moduleTag = [tag retain];
	}
	return self;
}

- (void) dealloc {
	[path release];
	[query release];
	[moduleTag release];
	[super dealloc];
}

- (void) setPath:(NSString *)aPath query:(NSString *)aQuery {
	if (path != aPath) {
		[path release];
		path = [aPath retain];
	}
	
	if (!aQuery) {
		aQuery = @"";
	}

	if (query != aQuery) {
		[query release];
		query = [aQuery retain];
	}
}
	
- (void) setPathWithViewController:(UIViewController *)viewController extension:(NSString *)extension {
	UIViewController *parentController = [[MIT_MobileAppDelegate moduleForTag:moduleTag] parentForViewController:viewController];
	MITModuleURL *parentURL = ((id<MITModuleURLContainer>)parentController).url;
    if (parentURL) {
        [self setPath:[NSString stringWithFormat:@"%@/%@", parentURL.path, extension] query:nil];
    } else {
        ELog(@"Attempting to load nil path");
    }
}
	
- (void) setAsModulePath {
	MITModule *module = [MIT_MobileAppDelegate moduleForTag:moduleTag];
	module.currentPath = path;
	module.currentQuery = query;
	//NSLog(@"Just saved module state: %@, %@  for module: %@", module.currentPath, module.currentQuery, module);
}

@end
