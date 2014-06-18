//
//  AVSESpliceCommand.h
//  AVSimpleEditoriOS
//
//  Created by Camvy Films on 2014-04-28.
//
//

#import "AVSECommand.h"
#import <MediaPlayer/MediaPlayer.h>

@interface AVSESpliceCommand : AVSECommand <MPMediaPickerControllerDelegate>

@property (strong, nonatomic)NSMutableArray *aRollArray;
@property (strong, nonatomic)NSMutableArray *bRollArray;
//state variables
@property int bShotCount;
@property int aShotCount;
@property CMTime timerWhole;
@property CMTime secondsRemainingInComposition, secondsRemainingInA;
@property BOOL isThereAnyALeft;
@property BOOL isThereAnyBLeft;
@property (copy) AVAsset  *aRollAsset;
@property (strong, nonatomic) AVAsset *altMusicAsset;

-(void)addAudio;

@end
