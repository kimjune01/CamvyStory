//
//  CMVTutorialView.m
//  Fun with Masks
//
//  Created by Camvy Films on 2014-06-05.
//  Copyright (c) 2014 Evan Davis. All rights reserved.
//

#import "CMVTutorialView.h"

@implementation CMVTutorialView

UIView *triangleCorner;
BOOL isTriangle;

- (id)initWithFrame:(CGRect)frame
{
    NSAssert(YES, @"You must init with a message or a title");
    self = [super initWithFrame:frame];
    return self;
}


- (id)initWithWidth:(CGFloat)width height:(CGFloat)height title:(NSString*)title andMessage:(NSString*)message withTriangle:(BOOL)triangle{
    CGRect frame = CGRectMake(0, 0, width, height);
    self = [super initWithFrame:frame];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CAShapeLayer *triangleLayer = [[CAShapeLayer alloc] init];
    
    
    CGFloat cornerSize = 55;
    UIView *mainView = [[UIView alloc]initWithFrame: frame];
    triangleCorner = [[UIView alloc]initWithFrame: CGRectMake(width-cornerSize,
                                                              height-cornerSize,
                                                              cornerSize,
                                                              cornerSize)];
    UILabel *titleLabel = [[UILabel alloc]init];
    UILabel *messageLabel = [[UILabel alloc]init];
    UILabel *bottomLabel = [[UILabel alloc]init];
    
    if (self) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddLineToPoint(path, NULL, width, 0);
        CGPathAddLineToPoint(path, NULL, width, height-cornerSize);
        CGPathAddLineToPoint(path, NULL, width-cornerSize, height);
        CGPathAddLineToPoint(path, NULL, 0, height);
        CGPathCloseSubpath(path);
        
        maskLayer.frame = mainView.layer.bounds;
        maskLayer.fillColor = [[UIColor whiteColor] CGColor];
        maskLayer.path = path;
        mainView.layer.mask = maskLayer;
        mainView.backgroundColor = [UIColor blackColor];
        mainView.alpha=.6;
        CGPathRelease(path);
        
        
        CGMutablePathRef trianglePath = CGPathCreateMutable();
        CGPathMoveToPoint(trianglePath, NULL, 0, cornerSize);
        CGPathAddLineToPoint(trianglePath, NULL, cornerSize, cornerSize);
        CGPathAddLineToPoint(trianglePath, NULL, cornerSize, 0);
        CGPathCloseSubpath(trianglePath);
        
        triangleLayer.frame = triangleCorner.layer.bounds;
        triangleLayer.fillColor = [[UIColor whiteColor] CGColor];
        triangleLayer.path = trianglePath;
        triangleCorner.layer.mask = triangleLayer;
        triangleCorner.backgroundColor = [UIColor blackColor];
        triangleCorner.alpha = .6;
        CGPathRelease(trianglePath);
        
        
        CGFloat topMargin = 40;
        CGFloat sideMargin = 35;
        CGFloat bottomMargin = 15;
        UIFont *lightHelvetica = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
        
        titleLabel.frame = CGRectMake(sideMargin, topMargin, width-sideMargin*2, height-bottomMargin-topMargin);
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.center = CGPointMake(width/2, topMargin+30);
        titleLabel.numberOfLines = 0;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        if (title==nil) {
            titleLabel.text = @"placeholder title text";
        }
        titleLabel.text = title;
        titleLabel.font = lightHelvetica;
        
        UIFont *ultralightHelvetica = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20];
        messageLabel.frame = CGRectMake(sideMargin, topMargin, width-sideMargin*2, height-bottomMargin-topMargin);
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.center = CGPointMake(width/2, height/2);
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        if (message==nil) {
            messageLabel.text = @"placeholder title text";
        }
        messageLabel.text = message;
        messageLabel.font = ultralightHelvetica;
        
        
        bottomLabel.frame = CGRectMake(0, 0, width-sideMargin*2, height-bottomMargin-topMargin);
        bottomLabel.textColor = [UIColor whiteColor];
        bottomLabel.center = CGPointMake(width/2, height-bottomMargin-30);
        bottomLabel.numberOfLines = 0;
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        bottomLabel.text = @"Tap to continue";
        bottomLabel.font = ultralightHelvetica;
        
    }
    
    [self addSubview:mainView];
    [self addSubview:triangleCorner];
    [self addSubview:titleLabel];
    [self addSubview:messageLabel];
    [self addSubview:bottomLabel];
    isTriangle = triangle;
    
    [self animateTriangle];
    
    return self;
}

-(void)initWithIcon1:(UIImage*)icon1 icon2:(UIImage*)icon2 icon3:(UIImage*)icon3 title:(NSString*)title sentence1:(NSString*)sentence1 sentence2:(NSString*)sentence2 sentence3:(NSString*)sentence3{
    
}


-(void)animateTriangle{
    [UIView animateWithDuration:.6
                          delay:.3
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         triangleCorner.alpha = 0.05;}
                     completion:NULL];
}

-(UIView*)makeTitleView:(NSString*)title{
    
    return nil;
}

-(UIView*)messageView:(NSString*)title{
    
    return nil;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (isTriangle) {
        [self animateTriangle];
    }
}




@end
