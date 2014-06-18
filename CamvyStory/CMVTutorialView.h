//
//  CMVTutorialView.h
//  Fun with Masks
//
//  Created by Camvy Films on 2014-06-05.
//  Copyright (c) 2014 Evan Davis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CMVTutorialView : UIView

- (id)initWithWidth:(CGFloat)width height:(CGFloat)height title:(NSString*)title andMessage:(NSString*)message withTriangle:(BOOL)triangle;
-(void)animateTriangle;

@end
