//
//  CMVLookupFilter.h
//  CamvyStory
//
//  Created by Camvy Films on 2014-06-04.
//  Copyright (c) 2014 Camvy Films. All rights reserved.
//

#import "GPUImageFilterGroup.h"
#import "GPUImagePicture.h"

@interface CMVLookupFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}
- (id)initWithImageName:(NSString*) imageName;
@end
