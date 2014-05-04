//
//  MoreInfoView.h
//  repWallet
//
//  Created by Alberto Fiore on 2/10/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "MoreInfoView.h"
#import "RMMapView.h"

@implementation MoreInfoView

@synthesize text, bottomtext, subbottomtext, btn, mapAnnotation, delegate, mapView;

- (BOOL) checkPixelTransparencyInImage:(UIImage *)im forPoint:(CGPoint) point 
{
    unsigned char pixel[1] = {0};
    CGContextRef context = CGBitmapContextCreate(pixel, 
                                                 1, 1, 8, 1, NULL,
                                                 kCGImageAlphaOnly);
    UIGraphicsPushContext(context);
    [im drawAtPoint:CGPointMake(-point.x, -point.y)];
    UIGraphicsPopContext();
    CGContextRelease(context);
    CGFloat alpha = pixel[0]/255.0;
    BOOL transparent = alpha < 0.01;
    return transparent;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    UIImage *im = self.image;
    CGPoint point = [recognizer locationInView:self];
    
    if ([self checkPixelTransparencyInImage:im forPoint:point]) {

        if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewWasTappedForLongOnTransparentPoint:)]) {
            [self.delegate moreInfoViewWasTappedForLongOnTransparentPoint:recognizer];
        }
    } 
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewBeganPanningGesture:)]) {
            [self.delegate moreInfoViewBeganPanningGesture:recognizer];
        }
    
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewBeganPanningGesture:)]) {
            [self.delegate moreInfoViewChangedPanningGesture:recognizer];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewEndedPanningGesture:)]) {
            [self.delegate moreInfoViewEndedPanningGesture:recognizer];
        }
    } 
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Detect touch anywhere
    UITouch *touch = [touches anyObject];
    
    switch ([touch tapCount]) 
    {
        case 1: // single touch
        {
//            NSLog(@"1 - %g %g", [touch locationInView:self.superview].x, [touch locationInView:self.superview].y);
            
            UIImage *im = self.image;
            CGPoint point = [touch locationInView:self];
            
            if ([self checkPixelTransparencyInImage:im forPoint:point]) {
          
                if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewWasTappedOnTransparentPoint:)]) {
                    [self.delegate moreInfoViewWasTappedOnTransparentPoint:touch];
                }
                
            } else
                ;
            
            break; 
        }
        
        case 2: // double touch
        {
            //            NSLog(@"1 - %g %g", [touch locationInView:self.superview].x, [touch locationInView:self.superview].y);
            
            UIImage *im = self.image;
            CGPoint point = [touch locationInView:self];
            
            if ([self checkPixelTransparencyInImage:im forPoint:point]) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(moreInfoViewWasDoubleTappedOnTransparentPoint:)]) {
                    [self.delegate moreInfoViewWasDoubleTappedOnTransparentPoint:touch];
                }
                
            } else
                ;
            
            break; 
        }
        
        default:
            break;
    }
}

-(id)initWithTarget:(id)target
{
    
    UIImage * img = [UIImage imageNamed:@"callout.png"];
    
    if (self = [super initWithImage:img]) {
        
        const CGFloat LABEL_HEIGHT = 20;
        
        self.userInteractionEnabled = YES;
        
        UILabel * l = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, 185, 20)];
        self.text = l;
        self.text.text = @"";
        self.text.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+2];
        self.text.backgroundColor = [UIColor clearColor];
        self.text.textColor = [UIColor whiteColor];
        [self addSubview:self.text];
        [l release];
        
        l = [[UILabel alloc] initWithFrame:CGRectMake(30, 10+LABEL_HEIGHT, 185, 20)];
        self.bottomtext = l;
        self.bottomtext.text = @"";
        self.bottomtext.font = [UIFont systemFontOfSize:[UIFont labelFontSize]-2];
        self.bottomtext.backgroundColor = [UIColor clearColor];
        self.bottomtext.textColor = [UIColor whiteColor];
        [self addSubview:self.bottomtext];
        [l release];
        
        l = [[UILabel alloc] initWithFrame:CGRectMake(30, 10+2*LABEL_HEIGHT, 185, 20)];
        self.subbottomtext = l;
        self.subbottomtext.text = @"";
        self.subbottomtext.font = [UIFont systemFontOfSize:[UIFont labelFontSize]-2];
        self.subbottomtext.backgroundColor = [UIColor clearColor];
        self.subbottomtext.textColor = [UIColor whiteColor];
        [self addSubview:self.subbottomtext];
        [l release];
        
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(230, 25, 30, 30)];
        self.btn = b;
        [b release];
        self.btn.backgroundColor = [UIColor clearColor];
        self.btn.hidden = NO;
        [self.btn setImage:[UIImage imageNamed:@"callout_acc_btn.png"] forState:UIControlStateNormal];
        [self.btn addTarget:target action:@selector(accessoryBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn];
        
        self.mapAnnotation = nil;
        
        UILongPressGestureRecognizer *longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        
        longPressRecognizer.minimumPressDuration = 0.8; // 0.8 seconds

        [self addGestureRecognizer:longPressRecognizer];
        
        UIPanGestureRecognizer *panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
        
        panRecognizer.maximumNumberOfTouches = 1;
        panRecognizer.minimumNumberOfTouches = 1;
        
        [self addGestureRecognizer:panRecognizer];

    }
    
    return self;
}

-(void)setupMapAnnotation:(MapAnnotation *)mapAnnotation 
{
    self.mapAnnotation = mapAnnotation;
    
    NSString *title = mapAnnotation.calloutTitle;
    NSString *subtitle = mapAnnotation.calloutSubtitle;
    NSString *subbottomtitle = mapAnnotation.calloutSubbottomtitle;
    
    if (title 
        && [[title stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        self.text.text = title;
    } else {
        self.text.text = @"<empty>";
    }
    
    if (subtitle 
        && [[subtitle stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        self.bottomtext.text = subtitle;
    } else {
        self.bottomtext.text = @"<empty>";
    }
    
    if (subbottomtitle 
        && [[subbottomtitle stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        self.subbottomtext.text = subbottomtitle;
    } else {
        self.subbottomtext.text = @"<empty>";
    }
}

-(void)dealloc
{
    [self.mapView release];
    [self.mapAnnotation release];
    [self.btn release];
    [self.subbottomtext release];
    [self.bottomtext release];
    [self.text release];
    [super dealloc];
}

@end
