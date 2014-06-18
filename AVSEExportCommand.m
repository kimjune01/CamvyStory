

#import "AVSEExportCommand.h"
#import "CompositionSingleton.h"

@interface AVSEExportCommand (Internal)

- (void)writeVideoToPhotoLibrary:(NSURL *)url;

@end

@implementation AVSEExportCommand

CompositionSingleton *sharedSingleton;

- (void)perform
{
    sharedSingleton = [[CompositionSingleton alloc]init];
	// Step 1
	// Create an outputURL to which the exported movie will be saved
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *outputURL = paths[0];
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
	outputURL = [outputURL stringByAppendingPathComponent:@"CamvyVideo.mp4"];
	// Remove Existing File
	[manager removeItemAtPath:outputURL error:nil];
    
	
	// Step 2
	// Create an export session with the composition and write the exported movie to the photo library
	self.exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPreset1280x720];
    
	self.exportSession.videoComposition = self.mutableVideoComposition;
	self.exportSession.audioMix = self.mutableAudioMix;
	self.exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
	self.exportSession.outputFileType=AVFileTypeQuickTimeMovie;
    
	[self.exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch (self.exportSession.status) {
			case AVAssetExportSessionStatusCompleted:
				[self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
				// Step 3
				// Notify AVSEViewController about export completion
				
				break;
			case AVAssetExportSessionStatusFailed:
				break;
			case AVAssetExportSessionStatusCancelled:
				break;
			default:
				break;
		}
	}];
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	
	[library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
		if (error) {
            sharedSingleton.errorMessage = [error localizedDescription];
            
		}
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:AVSEExportCommandCompletionNotification
         object:self];
	}];
    
    
}

@end
