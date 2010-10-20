#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class StoryXMLParser;
@class NewsImage;
@class NewsImageRep;

@protocol StoryXMLParserDelegate <NSObject>

- (void)parserDidFinishParsing:(StoryXMLParser *)parser;

@optional
- (void)parserDidStartDownloading:(StoryXMLParser *)parser;
- (void)parserDidStartParsing:(StoryXMLParser *)parser;
- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone;
- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error;
- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error;
@end

@interface StoryXMLParser : NSObject <ConnectionWrapperDelegate> {
    id <StoryXMLParserDelegate> delegate;
    
    ConnectionWrapper *connection;
    
    NSInteger expectedStoryCount;
    
    BOOL parsingTopStories;
    
	NSString *currentElement;
    NSMutableArray *currentStack;
    NSMutableDictionary *currentContents;
    NSMutableDictionary *currentImage;
	BOOL done;
    BOOL parseSuccessful;
    BOOL shouldAbort;
    
    NSMutableArray *newStories;
    
	NSAutoreleasePool *downloadAndParsePool;
}

@property (nonatomic, assign) id <StoryXMLParserDelegate> delegate;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, assign) BOOL parsingTopStories;
@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSMutableArray *currentStack;
@property (nonatomic, retain) NSMutableDictionary *currentContents;
@property (nonatomic, retain) NSMutableDictionary *currentImage;
@property (nonatomic, retain) NSMutableArray *newStories;
@property (nonatomic, assign) NSAutoreleasePool *downloadAndParsePool;

// called by main thread
- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count;
- (void)abort;


@end
