/*	FlowCoverView.h
 *
 *		FlowCover view engine; emulates CoverFlow.
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

// modified for MIT Mobile to trigger events when focused image changes
// and allow cache deletion for images that get updated


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "DataCache.h"

@protocol FlowCoverViewDelegate;

/*	FlowCoverView
 *
 *		The flow cover view class; this is a drop-in view which calls into
 *	a delegate callback which controls the contents. This emulates the CoverFlow
 *	thingy from Apple.
 */

@interface FlowCoverView : UIView 
{
	// Current state support
	double offset;
	
	NSTimer *timer;
	double startTime;
	double startOff;
	double startPos;
	double startSpeed;
	double runDelta;
	BOOL touchFlag;
	CGPoint startTouch;
	
	double lastPos;
	
	// Delegate
	IBOutlet id<FlowCoverViewDelegate> delegate;
	
	DataCache *cache;
	
	// OpenGL ES support
    GLint backingWidth;
    GLint backingHeight;
    EAGLContext *context;
    GLuint viewRenderbuffer, viewFramebuffer;
    GLuint depthRenderbuffer;
}

@property (assign) id<FlowCoverViewDelegate> delegate;

- (void)draw;					// Draw the FlowCover view with current state
- (void)clearCacheAtIndex:(int)index;

@end

/*	FlowCoverViewDelegate
 *
 *		Provides the interface for the delegate used by my flow cover. This
 *	provides a way for me to get the image, to get the total number of images,
 *	and to send a select message
 */

@protocol FlowCoverViewDelegate
- (int)flowCoverNumberImages:(FlowCoverView *)view;
- (UIImage *)flowCover:(FlowCoverView *)view cover:(int)cover;
- (void)flowCover:(FlowCoverView *)view didSelect:(int)cover;
- (void)flowCover:(FlowCoverView *)view didFocusOnCover:(int)cover;
@end
