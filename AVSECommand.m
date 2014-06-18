

#import "AVSECommand.h"

NSString* const AVSEEditCommandCompletionNotification = @"AVSEEditCommandCompletionNotification";
NSString* const AVSEExportCommandCompletionNotification = @"AVSEExportCommandCompletionNotification";

@implementation AVSECommand

- (id)initWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix
{
	self = [super init];
	if(self != nil) {
		self.mutableComposition = composition;
		self.mutableVideoComposition = videoComposition;
		self.mutableAudioMix = audioMix;
	}
	return self;
}

- (void)perform
{
	[self doesNotRecognizeSelector:_cmd];
}

@end
