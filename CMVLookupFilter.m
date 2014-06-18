//
//  CMVLookupFilter.m
//  CamvyStory
//
//  Created by Camvy Films on 2014-06-04.
//  Copyright (c) 2014 Camvy Films. All rights reserved.
//

#import "CMVLookupFilter.h"
#import "GPUImageLookupFilter.h"

@implementation CMVLookupFilter
- (id)init{
    NSAssert(NO, @"Call initWithImageName:");
    return self;
}
- (id)initWithImageName:(NSString*) imageName;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:imageName];
#else
    NSImage *image = [NSImage imageNamed:imageName];
#endif
    
    NSAssert(image, @"To use CMVLookupFilter you need to add %@ to your application bundle.", imageName);
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end
