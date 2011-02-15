/*	FlowCoverView.m
 *
 *		FlowCover view engine; emulates CoverFlow.
 *
 *	Copyright 2008 William Woody, all rights reserved.
 */


/***

Copyright 2008 William Woody, All Rights Reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

Neither the name of Chaos In Motion nor the names of its contributors may be 
used to endorse or promote products derived from this software without 
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
THE POSSIBILITY OF SUCH DAMAGE.

Contact William Woody at woody@alumni.caltech.edu or at 
woody@chaosinmotion.com. Chaos In Motion is at http://www.chaosinmotion.com

***/

#import "FlowCoverView.h"
#import <QuartzCore/QuartzCore.h>

/************************************************************************/
/*																		*/
/*	Internal Layout Constants											*/
/*																		*/
/************************************************************************/

#define TEXTURESIZE			256		// width and height of texture; power of 2, 256 max
#define MAXTILES			48		// maximum allocated 256x256 tiles in cache
#define VISTILES			6		// # tiles left and right of center tile visible on screen

/*
 *	Parameters to tweak layout and animation behaviors
 */

#define SPREADIMAGE			0.1		// spread between images (screen measured from -1 to 1)
#define FLANKSPREAD			0.4		// flank spread out; this is how much an image moves way from center
#define FRICTION			10.0	// friction
#define MAXSPEED			10.0	// throttle speed to this value

/************************************************************************/
/*																		*/
/*	Model Constants														*/
/*																		*/
/************************************************************************/

const GLfloat GVertices[] = {
	-1.0f, -1.0f, 0.0f,
	 1.0f, -1.0f, 0.0f,
	-1.0f,  1.0f, 0.0f,
	 1.0f,  1.0f, 0.0f,
};

const GLshort GTextures[] = {
	0, 0,
	1, 0,
	0, 1,
	1, 1,
};

/************************************************************************/
/*																		*/
/*	Internal FlowCover Object											*/
/*																		*/
/************************************************************************/

@interface FlowCoverRecord : NSObject
{
	GLuint	texture;
}
@property GLuint texture;
- (id)initWithTexture:(GLuint)t;
@end

@implementation FlowCoverRecord
@synthesize texture;

- (id)initWithTexture:(GLuint)t
{
	if (nil != (self = [super init])) {
		texture = t;
	}
	return self;
}

- (void)dealloc
{
	if (texture) {
		glDeleteTextures(1,&texture);
	}
	[super dealloc];
}

@end


@implementation FlowCoverView

@synthesize delegate;

/************************************************************************/
/*																		*/
/*	OpenGL ES Support													*/
/*																		*/
/************************************************************************/

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (BOOL)createFrameBuffer
{
	// Create an abstract frame buffer
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);

	// Create a render buffer with color, attach to view and attach to frame buffer
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
#if TARGET_IPHONE_SIMULATOR
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
#endif
        return NO;
    }
    
    return YES;
}

- (void)destroyFrameBuffer
{
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    [self destroyFrameBuffer];
    [self createFrameBuffer];
	[self draw];
}

/************************************************************************/
/*																		*/
/*	Construction/Destruction											*/
/*																		*/
/************************************************************************/

/*	internalInit
 *
 *		Handles the common initialization tasks from the initWithFrame
 *	and initWithCoder routines
 */

- (id)initInternally
{
	CAEAGLLayer *eaglLayer;
	
	eaglLayer = (CAEAGLLayer *)self.layer;
	eaglLayer.opaque = YES;
	
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	if (!context || ![EAGLContext setCurrentContext:context] || ![self createFrameBuffer]) {
		[self release];
		return nil;
	}
	self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
	
	cache = [[DataCache alloc] initWithCapacity:MAXTILES];
	offset = 0;
	
	return self;
}

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
		self = [self initInternally];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super initWithCoder:coder];
    if (self) {
		self = [self initInternally];
    }
    return self;
}

- (void)dealloc 
{
    [EAGLContext setCurrentContext:context];

	[self destroyFrameBuffer];
	[cache release];

	[EAGLContext setCurrentContext:nil];
    
	[context release];
    context = nil;
	[super dealloc];
}

/************************************************************************/
/*																		*/
/*	Delegate Calls														*/
/*																		*/
/************************************************************************/

- (int)numTiles
{
	if (delegate) {
		return [delegate flowCoverNumberImages:self];
	} else {
		return 0;		// test
	}
}

- (UIImage *)tileImage:(int)image
{
	if (delegate) {
		return [delegate flowCover:self cover:image];
	} else {
		return nil;		// should never happen
	}
}

- (void)touchAtIndex:(int)index
{
	if (delegate) {
		[delegate flowCover:self didSelect:index];
	}
}

/************************************************************************/
/*																		*/
/*	Tile Management														*/
/*																		*/
/************************************************************************/

static void *GData = NULL;

- (GLuint)imageToTexture:(UIImage *)image
{
	/*
	 *	Set up off screen drawing
	 */
	
	if (GData == NULL) GData = malloc(4 * TEXTURESIZE * TEXTURESIZE);
//	void *data = malloc(TEXTURESIZE * TEXTURESIZE * 4);
	CGColorSpaceRef cref = CGColorSpaceCreateDeviceRGB();
	CGContextRef gc = CGBitmapContextCreate(GData,
			TEXTURESIZE,TEXTURESIZE,
			8,TEXTURESIZE*4,
			cref,kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(cref);
	UIGraphicsPushContext(gc);
	
	/*
	 *	Set to transparent
	 */
	
	[[UIColor colorWithWhite:0 alpha:0] setFill];
	CGRect r = CGRectMake(0, 0, TEXTURESIZE, TEXTURESIZE);
	UIRectFill(r);
	
	/*
	 *	Draw the image scaled to fit in the texture.
	 */
	
	CGSize size = image.size;
	
	if (size.width > size.height) {
		size.height = 256 * (size.height / size.width);
		size.width = 256;
	} else {
		size.width = 256 * (size.width / size.height);
		size.height = 256;
	}
	
	r.origin.x = (256 - size.width)/2;
	r.origin.y = (256 - size.height)/2;
	r.size = size;
	[image drawInRect:r];
	
	/*
	 *	Create the texture
	 */
	
	UIGraphicsPopContext();
	CGContextRelease(gc);
	
	GLuint texture = 0;
	glGenTextures(1,&texture);
	[EAGLContext setCurrentContext:context];
	glBindTexture(GL_TEXTURE_2D,texture);
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,TEXTURESIZE,TEXTURESIZE,0,GL_RGBA,GL_UNSIGNED_BYTE,GData);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	
	free(GData);
	GData = NULL;
	
	/*
	 *	Done.
	 */
	
	return texture;
}

- (FlowCoverRecord *)getTileAtIndex:(int)index
{
	NSNumber *num = [NSNumber numberWithInt:index];
	FlowCoverRecord *fcr = [cache objectForKey:num];
	if (fcr == nil) {
		/*
		 *	Object at index doesn't exist. Create a new texture
		 */
		
		GLuint texture = [self imageToTexture:[self tileImage:index]];
		fcr = [[[FlowCoverRecord alloc] initWithTexture:texture] autorelease];
		[cache setObject:fcr forKey:num];
	}
	
	return fcr;
}

- (void)clearCacheAtIndex:(int)index {
	NSNumber *num = [NSNumber numberWithInt:index];
	FlowCoverRecord *fcr = [cache objectForKey:num];
    if (fcr != nil) {
        [cache removeObjectForKey:num];
    }
}


/************************************************************************/
/*																		*/
/*	Drawing																*/
/*																		*/
/************************************************************************/

- (void)drawTile:(int)index atOffset:(double)off
{
	FlowCoverRecord *fcr = [self getTileAtIndex:index];
	GLfloat m[16];
	memset(m,0,sizeof(m));
	m[10] = 1;
	m[15] = 1;
	m[0] = 1;
	m[5] = 1;
	double trans = off * SPREADIMAGE;
	
	double f = off * FLANKSPREAD;
	if (f < -FLANKSPREAD) {
		f = -FLANKSPREAD;
	} else if (f > FLANKSPREAD) {
		f = FLANKSPREAD;
	}
	m[3] = -f;
	m[0] = 1-fabs(f);
	double sc = 0.45 * (1 - fabs(f));
	trans += f * 1;
	
	glPushMatrix();
	glBindTexture(GL_TEXTURE_2D,fcr.texture);
	glTranslatef(trans, 0, 0);
	glScalef(sc,sc,1.0);
	glMultMatrixf(m);
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	
	// reflect
	glTranslatef(0,-2,0);
	glScalef(1,-1,1);
	glColor4f(0.5,0.5,0.5,0.5);
	glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	glColor4f(1,1,1,1);
	
	glPopMatrix();
    
    if (off == 0) {
        [self.delegate flowCover:self didFocusOnCover:index];
    }
}

- (void)draw
{
	/*
	 *	Get the current aspect ratio and initialize the viewport
	 */
	
	double aspect = ((double)backingWidth)/backingHeight;
	
	glViewport(0,0,backingWidth,backingHeight);
	glDisable(GL_DEPTH_TEST);				// using painters algorithm
	
	glClearColor(0,0,0,0);
	glVertexPointer(3,GL_FLOAT,0,GVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glTexCoordPointer(2, GL_SHORT, 0, GTextures);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	
	/*
	 *	Setup for clear
	 */
	
	[EAGLContext setCurrentContext:context];
	
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glClear(GL_COLOR_BUFFER_BIT);
	
	/*
	 *	Set up the basic coordinate system
	 */
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glScalef(1,aspect,1);
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	/*
	 *	Change from Alesandro Tagliati <alessandro.tagliati@gmail.com>:
	 *	We don't need to draw all the tiles, just the visible ones. We guess
	 *	there are 6 tiles visible; that can be adjusted by altering the 
	 *	constant
	 */
	
	int i,len = [self numTiles];
	int mid = (int)floor(offset + 0.5);
	int iStartPos = mid - VISTILES;
	if (iStartPos<0) {
		iStartPos=0;
	}
	for (i = iStartPos; i < mid; ++i) {
		[self drawTile:i atOffset:i-offset];
	}
	
	int iEndPos=mid + VISTILES;
	if (iEndPos >= len) {
		iEndPos = len-1;
	}
	for (i = iEndPos; i >= mid; --i) {
		[self drawTile:i atOffset:i-offset];
	}
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

/************************************************************************/
/*																		*/
/*	Animation															*/
/*																		*/
/************************************************************************/

- (void)updateAnimationAtTime:(double)elapsed
{
	int max = [self numTiles] - 1;
	
	if (elapsed > runDelta) elapsed = runDelta;
	double delta = fabs(startSpeed) * elapsed - FRICTION * elapsed * elapsed / 2;
	if (startSpeed < 0) delta = -delta;
	offset = startOff + delta;
	
	if (offset > max) offset = max;
	if (offset < 0) offset = 0;
	
	[self draw];
}

- (void)endAnimation
{
	if (timer) {
		int max = [self numTiles] - 1;
		offset = floor(offset + 0.5);
		if (offset > max) offset = max;
		if (offset < 0) offset = 0;
		[self draw];
		
		[timer invalidate];
		timer = nil;
	}
}

- (void)driveAnimation
{
	double elapsed = CACurrentMediaTime() - startTime;
	if (elapsed >= runDelta) {
		[self endAnimation];
        //NSLog(@"current tile is %d");
	} else {
		[self updateAnimationAtTime:elapsed];
	}
}

- (void)startAnimation:(double)speed
{
	if (timer) [self endAnimation];
	
	/*
	 *	Adjust speed to make this land on an even location
	 */
	
	NSLog(@"speed: %lf",speed);
	double delta = speed * speed / (FRICTION * 2);
	if (speed < 0) delta = -delta;
	double nearest = startOff + delta;
	nearest = floor(nearest + 0.5);
	startSpeed = sqrt(fabs(nearest - startOff) * FRICTION * 2);
	if (nearest < startOff) startSpeed = -startSpeed;
	
	runDelta = fabs(startSpeed / FRICTION);
	startTime = CACurrentMediaTime();
	
	NSLog(@"startSpeed: %lf",startSpeed);
	NSLog(@"runDelta: %lf",runDelta);
	timer = [NSTimer scheduledTimerWithTimeInterval:0.03
					target:self
					selector:@selector(driveAnimation)
					userInfo:nil
					repeats:YES];
}


/************************************************************************/
/*																		*/
/*	Touch																*/
/*																		*/
/************************************************************************/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect r = self.bounds;
	UITouch *t = [touches anyObject];
	CGPoint where = [t locationInView:self];
	startPos = (where.x / r.size.width) * 10 - 5;
	startOff = offset;
	
	touchFlag = YES;
	startTouch = where;
	
	startTime = CACurrentMediaTime();
	lastPos = startPos;
	
	[self endAnimation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect r = self.bounds;
	UITouch *t = [touches anyObject];
	CGPoint where = [t locationInView:self];
	double pos = (where.x / r.size.width) * 10 - 5;
	
	if (touchFlag == YES) {
		// Touched location; only accept on touching inner 256x256 area
		r.origin.x += (r.size.width - 256)/2;
		r.origin.y += (r.size.height - 256)/2;
		r.size.width = 256;
		r.size.height = 256;
		
		if (CGRectContainsPoint(r, where)) {
			[self touchAtIndex:(int)floor(offset + 0.01)];	// make sure .99 is 1
		}
	} else {
		// Start animation to nearest
		startOff += (startPos - pos);
		offset = startOff;

		double time = CACurrentMediaTime();
		double speed = (lastPos - pos)/(time - startTime);
		if (speed > MAXSPEED) speed = MAXSPEED;
		if (speed < -MAXSPEED) speed = -MAXSPEED;
		
		[self startAnimation:speed];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect r = self.bounds;
	UITouch *t = [touches anyObject];
	CGPoint where = [t locationInView:self];
	double pos = (where.x / r.size.width) * 10 - 5;

	if (touchFlag) {
		// determine if the user is dragging or not
		int dx = fabs(where.x - startTouch.x);
		int dy = fabs(where.y - startTouch.y);
		if ((dx < 3) && (dy < 3)) return;
		touchFlag = NO;
	}
	
	int max = [self numTiles]-1;
	
	offset = startOff + (startPos - pos);
	if (offset > max) offset = max;
	if (offset < 0) offset = 0;
	[self draw];
	
	double time = CACurrentMediaTime();
	if (time - startTime > 0.2) {
		startTime = time;
		lastPos = pos;
	}
}

@end
